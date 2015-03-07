module RedmineTocatClient
  module Patches
    module IssuesControllerPatch
      module InstanceMethods
        @@orders_errors= []
        def show_with_tocat_vars
          @orders = TocatOrder.all
          show_without_tocat_vars
        end

        def edit_with_tocat_vars
          @orders = TocatOrder.all
          edit_without_tocat_vars
        end

        def create_with_budgets
          status, message = @issue.tocat.set_budgets(params[:budgets])
          unless status
            @@orders_errors << message
            redirect_back_or_default edit_issue_path(@issue)
            return
          end
          @@orders_errors= []
          create_without_budgets
        end

        def update_with_budgets
          status, message = @issue.tocat.set_budgets(params[:budgets])
          unless status
            @@orders_errors << message
            redirect_back_or_default edit_issue_path(@issue)
            return
          end
          @@orders_errors= []
          update_without_budgets
        end
      end

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :show, :tocat_vars
          alias_method_chain :edit, :tocat_vars
          alias_method_chain :create, :budgets
          alias_method_chain :update, :budgets
        end
      end

    end
  end
end


unless IssuesController.included_modules.include?(RedmineTocatClient::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineTocatClient::Patches::IssuesControllerPatch)
end
