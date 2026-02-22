class ApplicationController < ActionController::Base
  Pagination = Struct.new(:page, :per_page, :total_count, :total_pages, :prev_page, :next_page, keyword_init: true)

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :require_basic_authentication

  private

  def require_basic_authentication
    return unless basic_auth_enabled?

    authenticate_or_request_with_http_basic("Hotel CRM") do |username, password|
      secure_match?(username, ENV["BASIC_AUTH_USERNAME"]) &&
        secure_match?(password, ENV["BASIC_AUTH_PASSWORD"])
    end
  end

  def basic_auth_enabled?
    ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
  end

  def secure_match?(input, expected)
    return false if expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(input.to_s),
      ::Digest::SHA256.hexdigest(expected.to_s)
    )
  end

  def paginate_scope(scope, per_page: 20)
    page = params[:page].to_i
    page = 1 if page < 1

    total_count = scope.count
    total_pages = (total_count.to_f / per_page).ceil
    total_pages = 1 if total_pages < 1
    page = total_pages if page > total_pages

    records = scope.offset((page - 1) * per_page).limit(per_page)
    pagination = Pagination.new(
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      prev_page: (page > 1 ? page - 1 : nil),
      next_page: (page < total_pages ? page + 1 : nil)
    )

    [pagination, records]
  end
end
