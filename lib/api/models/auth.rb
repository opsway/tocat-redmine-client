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
    end
  end
end
