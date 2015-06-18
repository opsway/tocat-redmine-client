require "rails_helper"

describe 'Tocat Invoice API' do
  before :all do
    @invoices = File.read('plugins/redmine_tocat_client/spec/support/fixtures/invoices/invoices.json')
    @invoice = File.read('plugins/redmine_tocat_client/spec/support/fixtures/invoices/invoice.json')
    @site = "http://tocat.test"
    TocatInvoice.site = @site
  end

  it 'should test collection path' do
    stub_request(:get, "#{@site}/invoices?current_user=Anonymous").
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => @invoices, :headers => {})
    response = TocatInvoice.find(:all)

    expect(response.first.external_id).to eq('test_1')
  end

  it 'should test element path' do
    stub_request(:get, "#{@site}/invoice/1?current_user=Anonymous").
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => @invoice, :headers => {})
    response = TocatInvoice.find(1)

    expect(response.external_id).to eq('test_1')
  end

  describe 'actions' do

    before(:each) do
      stub_request(:get, "#{@site}/invoice/1?current_user=Anonymous").
          with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => @invoice, :headers => {})
      @record = TocatInvoice.find(1)
    end

    it 'should make invoice paid' do
      stub = stub_request(:post, "#{@site}/invoice/1/paid?current_user=Anonymous").
          with(:headers => {'Accept'=>'*/*', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'})

      expect(@record.set_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should make invoice unpaid' do
      stub = stub_request(:delete, "#{@site}/invoice/1/paid?current_user=Anonymous").
          with(:headers => {'Accept'=>'application/json', 'User-Agent'=>'Ruby'})

      expect(@record.remove_paid).to eq([true, nil])
      expect(stub).to have_been_requested
    end

    it 'should get invoice feed' do
      feed = File.read('plugins/redmine_tocat_client/spec/support/fixtures/invoices/activity.json')
      stub = stub_request(:get, "#{@site}/activity?trackable=invoice&trackable_id=1&current_user=Anonymous").
          with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => feed, :headers => {})
      expect(@record.activity.first.key).to eq('invoice.paid_update')
      expect(stub).to have_been_requested
    end

    describe 'when server unavailable' do

      before(:each) do
        @exception = SocketError.new
        stub_request(:post, "#{@site}/invoice/1/paid?current_user=Anonymous").to_raise(@exception)
        stub_request(:delete, "#{@site}/invoice/1/paid?current_user=Anonymous").to_raise(@exception)
        stub_request(:get, "#{@site}/activity?trackable=invoice&trackable_id=1&current_user=Anonymous").to_raise(@exception)
      end

      it 'should not raise exception' do
        expect{@record.set_paid}.to_not raise_error
        expect{@record.remove_paid}.to_not raise_error
        expect{@record.activity}.to_not raise_error
      end

      it 'should fail gracefully' do
        expect(@record.set_paid).to eq([false, @exception])
        expect(@record.remove_paid).to eq([false, @exception])
        expect(@record.activity).to eq([])
      end
    end
  end
end