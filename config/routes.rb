require "sidekiq/web"
require "digest"

if ENV["BASIC_AUTH_USERNAME"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    expected_username = ENV["BASIC_AUTH_USERNAME"].to_s
    expected_password = ENV["BASIC_AUTH_PASSWORD"].to_s

    username_ok = ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(username.to_s),
      Digest::SHA256.hexdigest(expected_username)
    )
    password_ok = ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password.to_s),
      Digest::SHA256.hexdigest(expected_password)
    )

    username_ok && password_ok
  end
end

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health/sidekiq" => "health#sidekiq"

  mount Sidekiq::Web => "/sidekiq" if RuntimeMode.background_jobs_enabled?

  namespace :admin do
    root "dashboard#index"

    resources :members
    resources :vouchers
    resources :purchases
    resources :guest_stays, only: %i[index show]
    resources :import_runs, only: %i[index show]
    resources :promotion_campaigns, only: %i[index show new create]
    resource :settings, only: %i[edit update]
  end

  root to: redirect("/admin")
end
