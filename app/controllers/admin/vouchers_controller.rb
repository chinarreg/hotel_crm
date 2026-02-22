module Admin
  class VouchersController < BaseController
    before_action :set_voucher, only: %i[show edit update destroy]

    def index
      scope = Voucher.includes(:member).order(created_at: :desc)
      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        scope = scope.joins(:member).where(
          "LOWER(vouchers.voucher_code) LIKE :q OR LOWER(members.full_name) LIKE :q",
          q: query
        )
      end
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagination, @vouchers = paginate_scope(scope)
    end

    def show; end

    def new
      @voucher = Voucher.new
    end

    def create
      @voucher = Voucher.new(voucher_params)
      if @voucher.save
        redirect_to admin_voucher_path(@voucher), notice: "Voucher created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @voucher.update(voucher_params)
        redirect_to admin_voucher_path(@voucher), notice: "Voucher updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @voucher.destroy
      redirect_to admin_vouchers_path, notice: "Voucher deleted successfully."
    end

    private

    def set_voucher
      @voucher = Voucher.find(params[:id])
    end

    def voucher_params
      params.require(:voucher).permit(:property_id, :member_id, :voucher_code, :issued_on, :expiry_date, :status)
    end
  end
end
