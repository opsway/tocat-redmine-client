require 'plugin_helper'

describe 'Tocat Task API' do
  before :all do
    @site = "http://tocat.test/"
    TocatTicket.site = @site
    TocatUser.site = @site
    TocatOrder.site = @site
  end

  let!(:task) { FactoryGirl.build(:task) }
  let!(:tasks) { FactoryGirl.build_list(:task, 3) }

  it 'should test collection path' do
    webmock_collection(tasks)
    response = TocatTicket.find(:all)

    expect(response.first.external_id).to eq(tasks.first.external_id)
  end

  it 'should test element path' do
    webmock_element(task)
    response = TocatTicket.find(task.id)

    expect(response.external_id).to eq(task.external_id)
  end

  it 'should find ticket by its external id' do
    pending('need to refactor find_by_external_id class method')
    fail
  end

  describe 'setters' do
    before(:each) do
      webmock_element(task)
    end

    let!(:record) { TocatTicket.find(task.id) }

    it 'should make task accepted' do
      stub = webmock_action(task, 'post', 'accept')
      record.accepted = false

      expect(record.toggle_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should make task accepted' do
      stub = webmock_action(task, 'delete', 'accept')
      record.accepted = true

      expect(record.toggle_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should set resolver' do
      stub = webmock_action_with_body(task, 'post', 'resolver', {user_id: 1})

      expect(TocatTicket.update_resolver(task.id, 1)).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should remove resolver' do
      stub = webmock_action(task, 'delete', 'resolver')

      expect(TocatTicket.update_resolver(task.id, nil)).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should set budgets' do
      budgets = {order_id:Random.rand(10),budget:Random.rand}
      stub = webmock_action_with_body(task, 'post', 'budget', {budget: budgets})

      expect(TocatTicket.set_budgets(task.id, budgets)).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    describe 'when server unavailable' do
      let!(:exception) { SocketError.new }

      before(:each) do
        webmock_action(task, 'post', 'accept').to_raise(exception)
        webmock_action(task, 'delete', 'accept').to_raise(exception)
        webmock_action_with_body(task, 'post', 'resolver', {user_id: 1}).to_raise(exception)
        webmock_action(task, 'delete', 'resolver').to_raise(exception)
        webmock_action_with_body(task, 'post', 'budget', {budget: {}}).to_raise(exception)
      end

      it 'should not raise exception' do
        expect{task.toggle_paid}.to_not raise_error
        expect{TocatTicket.update_resolver(task.id, 1)}.to_not raise_error
        expect{TocatTicket.set_budgets(task.id, {})}.to_not raise_error
      end

      it 'should fail gracefully' do
        expect(task.toggle_paid).to eq([false, exception])
        expect(TocatTicket.update_resolver(task.id, 1)).to eq([false, exception])
        expect(TocatTicket.set_budgets(task.id, {})).to eq([false, exception])
      end
    end

  end

  describe 'getters' do
    let!(:paid) { FactoryGirl.build(:task, paid: true) }
    let!(:accepted) { FactoryGirl.build(:task, accepted: true) }
    let!(:invalid) { FactoryGirl.build(:invalid_task) }
    let!(:with_resolver) { FactoryGirl.build(:task) }
    let!(:with_orders) { FactoryGirl.build(:task_with_orders) }
    let!(:budgets) { [{order_id:Random.rand(10),budget:Random.rand}] }

    before(:each) do
      webmock_element(task)
      webmock_element(paid)
      webmock_element(accepted)
      webmock_element(invalid)
      webmock_element(with_resolver)
      webmock_element(with_orders)

    end

    let!(:not_accepted_and_paid) { TocatTicket.find(task.id) }
    let!(:accepted_record) { TocatTicket.find(accepted.id) }
    let!(:paid_record) { TocatTicket.find(paid.id) }
    let!(:invalid_record) { TocatTicket.find(invalid.id) }
    let!(:with_resolver_record) { TocatTicket.find(with_resolver.id) }
    let!(:with_orders_record) { TocatTicket.find(with_orders.id) }

    it 'should get paid' do
      expect(not_accepted_and_paid.get_paid).to eq(task.paid)
      expect(paid_record.get_paid).to eq(paid.paid)
      expect(invalid_record.get_paid).to eq(false)
    end

    it 'should get accepted' do
      expect(not_accepted_and_paid.get_accepted).to eq(task.accepted)
      expect(accepted_record.get_accepted).to eq(accepted.accepted)
      expect(invalid_record.get_accepted).to eq(false)
    end

    it 'should get budget' do
      expect(not_accepted_and_paid.get_budget).to eq(task.budget)
      expect(invalid.get_budget).to eq(0)
    end

    it 'should get resolver' do
      expect(with_resolver_record.get_resolver.name).to eq(with_resolver.resolver['name'])
      expect(invalid_record.get_resolver).to eq(nil)
    end

    it 'should get orders' do
      expect(with_orders_record.get_orders.last.name).to eq(with_orders.orders.last['name'])
      expect(invalid_record.get_orders).to eq([])
    end

    it 'should return orders' do
      order = FactoryGirl.build(:order, id: budgets.first[:order_id])
      webmock_element(order)
      webmock_action_with_body(task, 'get', 'budget', {budget: budgets})
      status, orders = TocatTicket.get_budgets(task.id)
      expect(orders.first.id).to eq(budgets.first[:order_id])
    end
  end
end