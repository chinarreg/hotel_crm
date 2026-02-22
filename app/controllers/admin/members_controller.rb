module Admin
  class MembersController < BaseController
    before_action :set_member, only: %i[show edit update destroy]

    def index
      scope = Member.order(created_at: :desc)
      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        scope = scope.where(
          "LOWER(full_name) LIKE :q OR LOWER(email) LIKE :q OR phone LIKE :q OR LOWER(membership_number) LIKE :q",
          q: query
        )
      end
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagination, @members = paginate_scope(scope)
    end

    def show; end

    def new
      @member = Member.new
    end

    def create
      @member = Member.new(member_params)
      if @member.save
        redirect_to admin_member_path(@member), notice: "Member created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @member.update(member_params)
        redirect_to admin_member_path(@member), notice: "Member updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @member.destroy
      redirect_to admin_members_path, notice: "Member deleted successfully."
    end

    private

    def set_member
      @member = Member.find(params[:id])
    end

    def member_params
      params.require(:member).permit(
        :property_id,
        :full_name,
        :phone,
        :email,
        :membership_number,
        :membership_start_date,
        :membership_expiry_date,
        :status
      )
    end
  end
end
