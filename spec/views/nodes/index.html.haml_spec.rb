
require 'spec_helper'

describe '/nodes/index' do
  before :each do
    @nodes = [Node.generate!]
  end

  describe "search fields" do
    before :each do
      view.stubs(
        :action_name => 'index',
        :parent => nil
      )
    end

    it "should not have :current or :successful if these aren't defined" do
      render
      rendered.should_not have_tag('.search input#current')
      rendered.should_not have_tag('.search input#successful')
    end

    it "should should have only :current if only it's defined" do
      params[:current] = "true"
      render
      rendered.should have_tag('.search input#current[type=hidden][value=true]')
      rendered.should_not have_tag('.search input#successful')
    end

    it "should should have only :successful if only it's defined" do
      params[:successful] = "false"
      render
      rendered.should_not have_tag('.search input#current')
      rendered.should have_tag('.search input#successful[type=hidden][value=false]')
    end

    it "should should both :current and :successful if both are defined" do
      params[:current] = "true"
      params[:successful] = "false"
      render
      rendered.should have_tag('.search input#current[type=hidden][value=true]')
      rendered.should have_tag('.search input#successful[type=hidden][value=false]')
    end
  end
end
