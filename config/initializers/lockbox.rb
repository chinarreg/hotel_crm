key = ENV["LOCKBOX_MASTER_KEY"] || Rails.application.credentials.dig(:lockbox, :master_key)

if key.blank?
  if Rails.env.production?
    raise "LOCKBOX_MASTER_KEY is required in production"
  end

  key = Lockbox.generate_key
end

Lockbox.master_key = key
