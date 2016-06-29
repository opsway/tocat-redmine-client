module RedmineTocatClient
  module Patches
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
          def render(options = nil, extra_options = {}, &block)
            # here you define related products
            if action_name == 'show' && @issue.present?
              @ticket = @issue.tocat
              begin
                temp = @issue.tocat.activity
              rescue
              ensure
                @journals += @issue.tocat.activity if @issue.tocat && @journals
                @journals.sort_by!(&:created_on) if @journals
              end
            end

            tocat_user = User.current.tocat
            @tocat_chart_data = nil
            if tocat_user
              balance_chart = TocatBalanceChart.new(tocat_user, 'one_week')
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
