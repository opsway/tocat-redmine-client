module AuthTocat
  def self.included(base)
    base.instance_eval do
      cattr_accessor :static_headers
      self.static_headers = headers
      def headers
        secret = RedmineTocatClient.settings[:apikey]
        new_headers = self.static_headers.clone
        token = JWT.encode({user_email: User.current.mail, exp: 24.hours.from_now.to_i },secret)
        new_headers['Authorization'] = token
        new_headers
      end
      if %w(TransferRequest TocatBalanceTransfer).include?(base.to_s)
        def element_path(id, prefix_options = {}, query_options = nil)
          prefix_options, query_options = split_options(prefix_options) if query_options.nil?
          "#{prefix(prefix_options)}#{collection_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
        end
      else
        def element_path(id, prefix_options = {}, query_options = nil)
          prefix_options, query_options = split_options(prefix_options) if query_options.nil?
          "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
        end
      end

      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
      end
    end
  end
end
