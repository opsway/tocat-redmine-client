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
    # @user = User.current
    # balance_account = RedmineTocatApi.get_user_accounts(@user, 'balance')
    # payment_account = RedmineTocatApi.get_user_accounts(@user, 'payment')
    # group_account = RedmineTocatApi.get_user_accounts(@user.dev_group, 'balance') if @user.dev_group
    # @accepted = Issue.where("resolver = ? AND accepted_paid = false AND accepted = true", @user.name)
    # @not_accepted = Issue.where("resolver = ? AND accepted_paid = false AND accepted = false", @user.name)
    # @payment_balance = 0
    # @team_balance = 0
    # @team_payment_balance = 0
    # @accepted_balance = 0
    # @not_accepted_balance = 0
    # @balance = 0
    #
    #
    #
    # if group_account
    #   group_transactions = RedmineTocatApi.get_transactions(group_account['ID'])
    #   group_transactions.each {|t| @team_balance += t["Total"].split("$ ")[1].gsub(",", "").to_d} if group_transactions
    # end
    # if @user.manager?
    #   group_payment_account = RedmineTocatApi.get_user_accounts(@user.dev_group, 'payment')
    #   if group_payment_account
    #     @group_payment_transactions = RedmineTocatApi.get_transactions(group_payment_account['ID'])
    #     @group_payment_transactions.each {|t| @team_payment_balance += t["Total"].split("$ ")[1].gsub(",", "").to_d} if @team_payment_balance
    #   end
    # else
    #   @accepted.all.each { |i| @accepted_balance += i.budget}
    #   @not_accepted.all.each { |i| @not_accepted_balance += i.budget}
    #   @accepted = @accepted.limit(10)
    #   @not_accepted = @not_accepted.limit(10)
    # end
    #
    # if payment_account
    #   @payment_transactions = RedmineTocatApi.get_transactions(payment_account['ID'])
    #   @payment_transactions.each {|t| @payment_balance += t["Total"].split("$ ")[1].gsub(",", "").to_d} if @payment_transactions
    # end
    # if balance_account
    #   @balance_transactions = nil
    #   @balance_transactions = RedmineTocatApi.get_transactions(balance_account['ID'])
    #   @balance_transactions.each {|t| @balance += t["Total"].split("$ ")[1].gsub(",", "").to_d} if @balance_transactions
    # end

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
