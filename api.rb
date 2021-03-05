require "sinatra"
require "sinatra/namespace"
require "sinatra/reloader" if development?
require "bcrypt"
require "json"

configure do
  enable :sessions
  set :session_secret, 'some crazy secret!'
end

get "/" do
  'This is an api! What are you doing here???'
end

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  get '/posts' do
    temp_posts = {post_id: 1, content: "Some post", author: "Some user"}
    temp_posts.to_json
  end
end