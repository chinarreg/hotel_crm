module Admin
  class GuestStaysController < BaseController
    def index
      scope = GuestStay.order(imported_at: :desc)
      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        scope = scope.where("LOWER(full_name) LIKE :q OR LOWER(email) LIKE :q OR phone LIKE :q", q: query)
      end
      @pagination, @guest_stays = paginate_scope(scope)
    end

    def show
      @guest_stay = GuestStay.find(params[:id])
    end
  end
end
