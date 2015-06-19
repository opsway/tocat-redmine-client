require 'plugin_helper'

describe 'Tocat Invoice API' do
  before :all do
    @site = "http://tocat.test/"
    TocatInvoice.site = @site
  end

  let!(:invoices) { FactoryGirl.build_list(:invoice, 3) }
  let!(:invoice) { FactoryGirl.build(:invoice) }

  it 'should test collection path' do
    webmock_collection(invoices)
    response = TocatInvoice.find(:all)

    expect(response.first.external_id).to eq(invoices.first.external_id)
  end

  it 'should test element path' do
    webmock_element(invoice)
    response = TocatInvoice.find(invoice.id)

    expect(response.external_id).to eq(invoice.external_id)
  end

  describe 'actions' do

    before(:each) do
      webmock_element(invoice)
    end

    let!(:record) { TocatInvoice.find(invoice.id) }

    it 'should make invoice paid' do
      stub = webmock_action(invoice, 'post', 'paid')

      expect(record.set_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should make invoice unpaid' do
      stub = webmock_action(invoice, 'delete', 'paid')

      expect(record.remove_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should get invoice feed' do
      stub = webmock_activity(@site, 'invoice', invoice.id)
      record.activity

      expect(stub).to have_been_requested
    end

    describe 'when server unavailable' do
      let!(:exception) { SocketError.new }

      before(:each) do
        webmock_action(invoice, 'post', 'paid').to_raise(exception)
        webmock_action(invoice, 'delete', 'paid').to_raise(exception)
        webmock_activity(@site, 'invoice', invoice.id).to_raise(exception)
      end

      it 'should not raise exception' do
        expect{record.set_paid}.to_not raise_error
        expect{record.remove_paid}.to_not raise_error
        expect{record.activity}.to_not raise_error
      end

      it 'should fail gracefully' do
        expect(record.set_paid).to eq([false, exception])
        expect(record.remove_paid).to eq([false, exception])
        expect(record.activity).to eq([])
      end
    end
  end
end