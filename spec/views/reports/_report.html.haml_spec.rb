require 'spec_helper'

describe "/reports/_report.html.haml" do
  include ReportsHelper

  describe "successful render" do
    before :each do
      assigns[:report] = @report = Report.generate!
      view.stubs(:resource => @report)
      render 'reports/report', :report => @report
    end

    it { rendered.should have_tag('span.status', :text => /Report/) }
  end
end
