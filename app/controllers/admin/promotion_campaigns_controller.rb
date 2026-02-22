module Admin
  class PromotionCampaignsController < BaseController
    before_action :set_campaign, only: %i[show]

    def index
      scope = PromotionCampaign.order(created_at: :desc)
      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        scope = scope.where("LOWER(name) LIKE :q OR LOWER(template_name) LIKE :q", q: query)
      end
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagination, @campaigns = paginate_scope(scope)
    end

    def show
      @pagination, @recipients = paginate_scope(@campaign.campaign_recipients.order(created_at: :desc), per_page: 25)
    end

    def new
      @campaign = PromotionCampaign.new
    end

    def create
      @campaign = PromotionCampaign.new(campaign_params)
      @campaign.status = initial_campaign_status
      @campaign.variables = parse_variables(params.dig(:promotion_campaign, :variables_input))
      @campaign.source_file = params.dig(:promotion_campaign, :contacts_file)&.original_filename

      if @campaign.save
        PromotionCampaigns::BuildRecipientsService.new(campaign: @campaign, upload_io: params.dig(:promotion_campaign, :contacts_file)).call
        if RuntimeMode.background_jobs_enabled?
          ProcessPromotionCampaignJob.perform_async(@campaign.id)
          redirect_to admin_promotion_campaign_path(@campaign), notice: "Campaign queued successfully."
        elsif RuntimeMode.sync_processing_enabled?
          ProcessPromotionCampaignJob.new.perform(@campaign.id)
          redirect_to admin_promotion_campaign_path(@campaign), notice: "Campaign processed synchronously."
        else
          redirect_to admin_promotion_campaign_path(@campaign), alert: "Background jobs are disabled. Campaign saved as draft and not queued."
        end
      else
        render :new, status: :unprocessable_entity
      end
    rescue StandardError => e
      flash.now[:alert] = "Unable to create campaign: #{e.message}"
      render :new, status: :unprocessable_entity
    end

    private

    def set_campaign
      @campaign = PromotionCampaign.find(params[:id])
    end

    def campaign_params
      params.require(:promotion_campaign).permit(:property_id, :name, :audience_type, :template_name)
    end

    def parse_variables(input)
      return [] if input.blank?

      input.to_s.split(",").map(&:strip)
    end

    def initial_campaign_status
      return :queued if RuntimeMode.background_jobs_enabled? || RuntimeMode.sync_processing_enabled?

      :draft
    end
  end
end
