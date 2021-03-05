require "sinatra"
require "sinatra/namespace"
require "sinatra/reloader" if development?
require "bcrypt"
require "json"

class User
  def self.get(user_id)
    user = DB.get("users", {id: user_id})
    {
      user_id: user_id,
      username: user[:username],
      bio: user[:bio]
    }
  end

  def self.authenticate(params)
    user = DB.get("users", {id: params[:user_id]})
    user[:password] == params[:password]
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
    @user = User.get(session[:user_id]))
  end

  get "/" do
    "hello anon"
  end

  get "/protected", :auth => :user do
    "Hello, #{@user.name}"
  end

  post "/login" do
    session[:user_id] = User.authenticate(params).id
  end

  post "/logout" do
    session[:user_id] = nil
  end
end