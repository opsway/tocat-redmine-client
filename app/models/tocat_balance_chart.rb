class TocatBalanceChart
  TRANSACTIONS_LIMIT = 9999999

  attr_reader :tocat_user

  def initialize(tocat_user)
    @tocat_user = tocat_user
  end

  def chart_data_for(period_identifier)
    chart_data(PresetPeriods.period(period_identifier))
  end

  def chart_data(period)
    @balance_chart = { balance: [], forecast: [], zero_line: [], timeline: [] }
    @accepted_tasks = TocatTicket.get_accepted_tasks(true, tocat_user.id)
    balance_transactions_by_date = user_balance_transactions_sum_by_date(tocat_user, period)

    balance_transactions_ = balance_transactions(tocat_user, period)
    accepted_not_paid_events = TocatTicket.events_for(@accepted_tasks.collect(&:task_id), 'task.accepted_update')
    balance_with_tasks = balance =  tocat_user.balance_account_state - balance_transactions_.sum { |r| r.total.to_i}

    accepted_not_paid_events = accepted_not_paid_events.select{ |r| r.parameters['new'] }.uniq(&:id)
    period.each do |date|
      events_sum = accepted_not_paid_events.select{ |r| r.created_at.to_date == date }.sum { |r| r.parameters['balance'].to_i }
      transactions_sum = balance_transactions_by_date.fetch(date.to_s, 0)
      balance_with_transactions = (balance += transactions_sum).round(2)
      forecast_balance = (balance_with_tasks += (events_sum + transactions_sum)).round(2)

      @balance_chart[:balance] << balance_with_transactions
      if tocat_user.tocat_server_role.name == 'Manager'
        @balance_chart[:forecast] << balance_with_transactions
      else
        @balance_chart[:forecast] << forecast_balance
      end
      @balance_chart[:zero_line] << 0
      @balance_chart[:timeline] << date
    end
    @balance_chart
  end

  private

  def user_balance_transactions_sum_by_date(tocat_user, period)
    user_balance_transactions(tocat_user, period)
      .group_by { |t| t.date.to_date.to_s }
      .each_with_object({}) do |(date, date_transactions), transactions_sums|
      transactions_sums[date] = date_transactions.sum { |r| r.total.to_i }
    end
  end

  def user_balance_transactions(tocat_user, period)
    search = [
      'account = balance',
      "created_at >= #{period.begin.strftime('%Y-%m-%d')}"
    ].join(' ')
    TocatTransaction.find(:all, params: { user: tocat_user.id, search: search, limit: TRANSACTIONS_LIMIT })
  end

  def balance_transactions(tocat_user, period)
    search = [
      'accountable_type == User',
      "accountable_id == #{tocat_user.id}",
      "created_at >= #{period.begin.strftime('%Y-%m-%d')}",
      'account = balance'
    ].join(' ')
    TocatTransaction.find(:all, params: { search: search, limit: TRANSACTIONS_LIMIT })
  end

  class PresetPeriods
    DEFAULT_PERIOD = ->(date) { date_quarter_period(date) }
    PRESET_PERIODS = {
      'this_quarter' => ->(date) { date_quarter_period(date) },
      'previous_quarter' => ->(date) { date_quarter_period(date - 3.months) }
    }

    class << self
      def period(period_identifier)
        PRESET_PERIODS.fetch(period_identifier, DEFAULT_PERIOD).call(Time.zone.today)
      end

      private

      def date_quarter_period(date)
        Range.new(date.at_beginning_of_quarter, date.at_end_of_quarter)
      end
    end
  end
end
