class PagesController < ApplicationController
  caches_action :home, :layout => false, :expires_in => 5.minutes, :cache_path => Proc.new { |c| c.request.request_uri }

  def home
    @all_nodes = Node.unhidden.by_report_date

    @unreported_nodes         = @all_nodes.unreported
    @unresponsive_nodes       = @all_nodes.unresponsive
    @failed_nodes             = @all_nodes.failed
    @pending_nodes            = @all_nodes.pending
    @changed_nodes            = @all_nodes.changed
    @unchanged_nodes          = @all_nodes.unchanged
  end

  def header
    respond_to do |format|
      format.html { render :partial => 'shared/global_nav' }
    end
  end

end
