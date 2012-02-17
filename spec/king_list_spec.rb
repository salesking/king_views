require 'spec_helper'

describe PostsController, :type => :controller do
  render_views
  describe "index" do
    it "shows list" do
      100.times do |i|
        Post.create( :title=> "hello world #{i}")
      end
      get :index

      #expect do
      #    end.to take_less_than(1).seconds

      response.body.should_not be_nil
      end

  end
end