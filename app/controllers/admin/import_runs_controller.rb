module Admin
  class ImportRunsController < BaseController
    def index
      scope = ImportRun.order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagination, @import_runs = paginate_scope(scope)
    end

    def show
      @import_run = ImportRun.find(params[:id])
    end
  end
end
