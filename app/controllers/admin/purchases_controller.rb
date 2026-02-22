module Admin
  class PurchasesController < BaseController
    before_action :set_purchase, only: %i[show edit update destroy]

    def index
      scope = Purchase.includes(:member).order(created_at: :desc)
      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        scope = scope.joins(:member).where("LOWER(members.full_name) LIKE :q", q: query)
      end
      scope = scope.where(payment_mode: params[:payment_mode]) if params[:payment_mode].present?
      @pagination, @purchases = paginate_scope(scope)
    end

    def show; end

    def new
      @purchase = Purchase.new
    end

    def create
      @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to admin_purchase_path(@purchase), notice: "Purchase created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @purchase.update(purchase_params)
        redirect_to admin_purchase_path(@purchase), notice: "Purchase updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @purchase.destroy
      redirect_to admin_purchases_path, notice: "Purchase deleted successfully."
    end

    private

    def set_purchase
      @purchase = Purchase.find(params[:id])
    end

    def purchase_params
      params.require(:purchase).permit(:property_id, :member_id, :amount, :purchased_on, :payment_mode)
    end
  end
end
