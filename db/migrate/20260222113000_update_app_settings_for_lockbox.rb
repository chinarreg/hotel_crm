class UpdateAppSettingsForLockbox < ActiveRecord::Migration[8.0]
  def change
    add_column :app_settings, :encrypted_value, :text unless column_exists?(:app_settings, :encrypted_value)
    remove_column :app_settings, :encrypted, :boolean if column_exists?(:app_settings, :encrypted)
  end
end
