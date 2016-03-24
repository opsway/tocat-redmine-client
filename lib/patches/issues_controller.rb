module RedmineTocatClient
  module Patches
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
          def render(options = nil, extra_options = {}, &block)
            # here you define related products
            if action_name == 'show' && @issue.present?
              begin
                temp = @issue.tocat.activity
              rescue
              ensure
                @journals += @issue.tocat.activity
                @journals.sort_by!(&:created_on)
              end
            end

            tocat_user = User.current.tocat
            @my_tocat_balance = nil
            @tocat_chart_data = nil
            if tocat_user
              balance_chart = TocatBalanceChart.new(tocat_user, 'two_weeks')
              @my_tocat_balance = balance_chart.current_period_delta
              @tocat_chart_data = balance_chart.chart_data
            end

            # don't forget to call super
            super(options, extra_options, &block)
          end
        end
      end
    end
  end
end


unless IssuesController.included_modules.include?(RedmineTocatClient::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineTocatClient::Patches::IssuesControllerPatch)
end
