class ImapPollJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 3

  def perform(property_id = nil)
    ImapFetchJob.new.perform(property_id)
  end
end
