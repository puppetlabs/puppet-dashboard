require 'spec_helper'

describe "/reports/_report_status_icon.html.haml" do
  include ReportsHelper

  describe "successful render" do
    before :each do
      assigns[:report] = @report = Report.generate!(:status => "changed")
      view.stubs(:resource => @report)
      render :partial => 'reports/report_status_icon', :locals => { :report => @report }
    end

    it { rendered.should have_tag('img', :with => { :src => '/images/icons/changed.png' }) }
  end
end
