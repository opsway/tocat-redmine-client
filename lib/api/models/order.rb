class TocatOrder < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'orders'
  self.element_name = 'order'
  add_response_method :http_response

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


  schema do
    attribute 'id', :integer
    attribute 'parent_order', :string
    attribute 'name', :string
    attribute 'description', :text
    attribute 'team', :string
    decimal 'invoiced_budget', 'allocatable_budget', 'free_budget'
  end

  def self.find_by_name(name)
    all_records = Team.all
    all_records.each { |r| return Team.find(r.id) if r.name == name }
    nil
  end

  def get_team
    team
  end

  def parent
    !parent_order.attributes.empty? ?
      TocatOrder.find(parent_order.id) :
      nil
  end

  def fmr
    (100 * (allocatable_budget/invoiced_budget)).round(2)
  end


  def get_invoice
    unless invoice.attributes.empty?
      return TocatInvoice.find(invoice.id)
    end
    nil
  end

  def editable?
    true
  end

  protected

  def to_json(options = {})
    self.attributes[:team] = {:id => attributes[:team]}
    self.attributes.to_json(options)
  end
end
