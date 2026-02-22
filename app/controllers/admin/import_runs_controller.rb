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

    def trigger_imap
      if RuntimeMode.background_jobs_enabled?
        ImapFetchJob.perform_async
        redirect_to admin_import_runs_path, notice: "IMAP fetch job queued successfully."
        return
      end

      unless RuntimeMode.sync_processing_enabled?
        redirect_to admin_import_runs_path, alert: "Background jobs are disabled. Enable sync processing to run IMAP import manually."
        return
      end

      result = Imap::ImapFetcherService.new.call
      imported_runs = 0
      result.files.each do |file|
        Imports::CsvImportService.new(file_path: file[:path]).call
        imported_runs += 1
      end

      notice = "Manual IMAP import completed. Files processed: #{imported_runs}."
      notice += " Message errors: #{result.errors.size}." if result.errors.any?
      redirect_to admin_import_runs_path, notice: notice
    rescue StandardError => e
      redirect_to admin_import_runs_path, alert: "Manual IMAP import failed: #{e.message}"
    end
  end
end
