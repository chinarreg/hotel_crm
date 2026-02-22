require "rails_helper"

RSpec.describe Whatsapp::Providers::MetaProvider, type: :service do
  let(:provider) { described_class.new(api_key: "token", phone_id: "123") }

  it "returns failed result on http exception" do
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:write_timeout=)
    allow(http).to receive(:request).and_raise(Timeout::Error)

    result = provider.send_template(phone: "9999999999", template_name: "promo", variables: ["A"])

    expect(result.success?).to eq(false)
    expect(result.error).to be_a(Timeout::Error)
  end
end
