require "rails_helper"

RSpec.describe SendBirthdayJob, type: :job do
  it "uses birthday template" do
    service = instance_double(WhatsappService)
    allow(WhatsappService).to receive(:new).and_return(service)
    allow(service).to receive(:send_template).and_return(WhatsappService::Result.new(success?: true, attempts: 1, status: 200))

    described_class.new.perform("9999999999", ["John"])

    expect(service).to have_received(:send_template).with("9999999999", "birthday_template", ["John"])
  end
end
