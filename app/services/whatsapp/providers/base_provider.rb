module Whatsapp
  module Providers
    class BaseProvider
      Result = Struct.new(:success?, :status, :body, :error, keyword_init: true)

      def send_template(phone:, template_name:, variables:)
        raise NotImplementedError
      end
    end
  end
end
