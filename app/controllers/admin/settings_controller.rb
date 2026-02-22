module Admin
  class SettingsController < BaseController
    def edit
      @settings = AppSetting::KEYS.index_with { |key| AppSetting.get(key, "") }
    end

    def update
      Settings::Updater.new(settings_params.to_h).call
      redirect_to edit_admin_settings_path, notice: "Settings updated successfully."
    rescue StandardError => e
      flash.now[:alert] = "Unable to save settings: #{e.message}"
      @settings = AppSetting::KEYS.index_with { |key| settings_params.to_h[key] || AppSetting.get(key, "") }
      render :edit, status: :unprocessable_entity
    end

    private

    def settings_params
      params.require(:settings).permit(*AppSetting::KEYS)
    end
  end
end
