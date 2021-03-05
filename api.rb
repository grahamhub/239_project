require "sinatra"
require "sinatra/namespace"
require "sinatra/reloader" if development?
require "bcrypt"
require "json"

class User; end

class API < Sinatra::Base
  set :sessions => true

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