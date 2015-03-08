class TocatTeam < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.element_name = 'team'
  self.collection_name = 'teams'

  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end
  end


  def self.find_by_name(name)
    TocatTeam.all.each { |team| return team if team.name == name }
  end

  def self.available_for_issue(issue)
    TocatTeam.all
  end
end
