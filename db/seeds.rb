property = Property.find_or_create_by!(code: "RBNAG") do |record|
  record.name = "Radisson Blu Nagpur"
  record.active = true
end

settings_defaults = {
  "whatsapp_api_key" => "",
  "whatsapp_phone_id" => "",
  "imap_host" => "imap.example.com",
  "imap_port" => "993",
  "imap_username" => "",
  "imap_password" => "",
  "imap_folder" => "INBOX",
  "csv_mapping_json" => {
    "full_name" => "full_name",
    "phone" => "phone",
    "email" => "email",
    "checkin_date" => "checkin_date",
    "checkout_date" => "checkout_date"
  }.to_json
}

settings_defaults.each do |key, value|
  next if value.blank?

  AppSetting.set(key, value)
end

member = Member.find_or_create_by!(membership_number: "RBM-0001") do |record|
  record.property = property
  record.full_name = "Sample Member"
  record.phone = "9999999999"
  record.email = "member@example.com"
  record.membership_start_date = Date.current
  record.membership_expiry_date = Date.current + 1.year
  record.status = :active
end

Voucher.find_or_create_by!(voucher_code: "VOUCHER-0001") do |record|
  record.property = property
  record.member = member
  record.issued_on = Date.current
  record.expiry_date = Date.current + 30.days
  record.status = :issued
end

Purchase.find_or_create_by!(member:, purchased_on: Date.current, amount: 4999.0) do |record|
  record.property = property
  record.payment_mode = :card
end
