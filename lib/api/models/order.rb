class TocatOrder < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'order'

  def self.find_by_name(name)
    all_records = Team.all
    all_records.each { |r| return Team.find(r.id) if r.name == name }
    nil
  end

  def get_team
    Group.where(lastname: team.name).first
  end

  def fmr
    (100 * (allocatable_budget/invoiced_budget)).round(2)
  end

  def get_suborders
    #TODO REFACTOR!!!
    suborders = []
    get(:suborder).each do |suborder|
      suborders << TocatOrder.find(suborder['id'])
    end
    suborders
  end

  def get_tasks
    #TODO REFACTOR!!!
    tasks = []
    all_tasks = TocatTicket.all
    unless all_tasks.nil?
      all_tasks.each do |task|
        if task.get(:order).each { |o| o['id'] == id }
          tasks << TocatTicket.find(task.id)
        end
      end
    end
    tasks
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
