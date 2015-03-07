class TocatController < ApplicationController
  unloadable
  layout 'tocat_base'
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  before_filter :check_for_setup


  def show_invoice
    @invoice = TocatInvoice.find(params[:invoice_id])
    respond_to do |format|
      format.html { render :template => 'tocat/invoices/show_invoice' }
    end
  end


  def invoices
    @invoices = TocatInvoice.all
    respond_to do |format|
      format.html { render :template => 'tocat/invoices' }
    end
  end

  def my_tocat
    @user = User.last #User.current [FIXME]
    @user_tocat = TocatUser.find(4)
    @team_tocat = TocatTeam.find(@user_tocat.team.id)
    transactions = TocatTransaction.get_transactions_for_user(@user_tocat.id)
    @balance_transactions = []
    @income_transactions = []
    transactions.each do |t|
      t.type == 'balance' ?
        @balance_transactions << t :
        @income_tranactions << t
    end
    transactions = TocatTransaction.get_transactions_for_team(@team_tocat.id)
    @team_balance_transactions = []
    @team_income_transactions = []
    transactions.each do |t|
      t.type == 'balance' ?
        @team_balance_transactions << t :
        @team_income_transactions << t
    end
    respond_to do |format|
      format.html { render :template => 'tocat/my_tocat' }
    end
  end

  private

  def check_for_setup
    errors = false
    errors = true unless RedmineTocatClient.settings[:host].present?

    if errors
      respond_to do |format|
        format.html { render(:template => 'error', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
      end
    end
  end


end
