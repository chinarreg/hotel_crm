require "net/http"
require "json"

module Whatsapp
  module Providers
    class MetaProvider < BaseProvider
      def initialize(api_key:, phone_id:, api_base_url: nil, open_timeout: 5, read_timeout: 10, write_timeout: 10)
        @api_key = api_key
        @phone_id = phone_id
        @api_base_url = api_base_url || ENV.fetch("WHATSAPP_API_BASE_URL", "https://graph.facebook.com/v20.0")
        @open_timeout = open_timeout
        @read_timeout = read_timeout
        @write_timeout = write_timeout
      end

      def send_template(phone:, template_name:, variables:)
        uri = URI("#{@api_base_url}/#{@phone_id}/messages")
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = payload(phone:, template_name:, variables:).to_json

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        http.write_timeout = @write_timeout if http.respond_to?(:write_timeout=)

        response = http.request(request)

        if response.code.to_i.between?(200, 299)
          Result.new(success?: true, status: response.code.to_i, body: response.body)
        else
          Result.new(success?: false, status: response.code.to_i, body: response.body, error: "non_success_status")
        end
      rescue StandardError => e
        Result.new(success?: false, status: nil, body: nil, error: e)
      end

      private

      def payload(phone:, template_name:, variables:)
        {
          messaging_product: "whatsapp",
          to: phone,
          type: "template",
          template: {
            name: template_name,
            language: { code: "en" },
            components: [
              {
                type: "body",
                parameters: Array(variables).map { |value| { type: "text", text: value.to_s } }
              }
            ]
          }
        }
      end
    end
  end
end
