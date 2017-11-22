class TocatDailyRateHistory < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'rates_history'
  self.element_name = 'rates_history'
  add_response_method :http_response
  include AuthTocat

  schema do
    attribute 'id', :integer
    attribute 'daily_rate', :decimal
    attribute 'timestamp_from', :date
    attribute 'timestamp_to', :date
  end

  protected

end
