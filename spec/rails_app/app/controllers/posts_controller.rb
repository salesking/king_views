class PostsController < ActionController::Base

  def index
    @posts = Post.find :all
  end
end
