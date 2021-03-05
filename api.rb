require "sinatra"
require "sinatra/reloader" if development?
require "bcrypt"
require "json"

class User
  def self.get(user_id)
    user = DB.get("users", {id: user_id})
    {
      id: user_id,
      username: user[:username],
      bio: user[:bio]
    }
  end

  def self.authenticate(params)
    user = DB.get("users", {id: params[:user_id]})
    
    if user[:password] == params[:password]
      return self.get(user[:id])
    end

    nil
  end
  
  def self.post(params)
    DB.add("posts", params)
  end

  def self.comment(params)
    DB.add("comments", params)
  end

  def self.remove_post(post_id)
    DB.remove("posts", post_id)
  end

  def self.remove_comment(comment_id)
    DB.remove("comments", comment_id)
  end
end

class API < Sinatra::Base
  set :sessions => true

  register do
    def auth(type)
      condition do
        403 unless send("is_#{type}?")
      end
    end
  end

  helpers do
    def is_user?
      @user != nil
    end
  end

  before do
    @user = User.get(session[:user][:id]))
    content_type 'application/json'
  end

  get "/profile", :auth => :user do
    User.get(params[:user_id]).to_json
  end

  get "/posts", :auth => :user do
    DB.get("posts").to_json
  end

  post "/posts" :auth => :user do
    return 201 if User.post(params)

    500
  end

  get "/comments", :auth => :user do
    DB.get("comments", {id: params[:post_id]}).to_json
  end

  post "/comments", :auth => :user do
    return 201 if User.comment(params)

    500
  end

  post "/login" do
    session[:user] = User.authenticate(params)
  end

  post "/logout" do
    session[:user] = nil
  end
end