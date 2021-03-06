require "sinatra/base"
require_relative "lib/sinatra/sessionauth"
require "pg"
require "json"

module App
  def self.start!
    App::API.run!
  end

  class DB
    def initialize
      @db = if Sinatra::Base.production?
              PG.connect(ENV['DATABASE_URL'])
            else
              PG.connect(dbname:"db230")
            end
    end
  
    def disconnect
      @db.close
    end
  
    def query(statement, *params)
      @db.exec_params(statement, params)
    end
  
    def get(table_name, params={}) 
      table = @db.quote_ident(table_name)
  
      sql = "SELECT * FROM #{table}"
      
      if params.size > 0
        sql += " WHERE"
        num = 1
        params.each do |key, value|
          type = (value.is_a? Integer) ? "::int" : "::text"
          sql += " #{key}=$#{num}#{type} "
          sql += "AND" if num < params.size
          num += 1
        end
      end
      
      result = query(sql, *params.values)
  
      results = {}
  
      result.each do |row|
        id = row["id"].to_i
        row_info = {}
        row_info[id] = {}
        
        row.each do |key, val|
          row_info[id][key.to_sym] = val unless key == "id"
        end

        results.merge! row_info
      end
  
      results
    end
  
    def add(table_name, params)
      table = @db.quote_ident(table_name)
      sql = "INSERT INTO #{table} VALUES (DEFAULT, $1::text, $2::int)"

      result = nil

      if table_name == "posts"
        result = query(sql, params[:content], params[:user_id])
      elsif table_name == "comments"
        result = query(sql, params[:content], params[:post_id])
      end
    
      result.result_status == 1
    end
  
    def remove(table_name, id)
      related_table_name = nil
      fkey = nil

      if table_name == "posts"
        related_table_name = "comments"
        fkey = "post_id"
      end
      
      table = @db.quote_ident(table_name)
      related_table = @db.quote_ident(related_table_name) if related_table_name
      
      sql = "DELETE FROM #{table} VALUES WHERE id = $1::int"
      related_sql = "DELETE FROM #{related_table} VALUES WHERE #{fkey} = $1::int"

      if fkey
        related_result = query(related_sql, id)
      else
        related_result = true
      end

      result = query(sql, id)

      result.result_status == 1 && (related_result == true || related_result.result_status == 1)
    end
  end

  class User
    def self.connect_db(db)
      @@database = db
    end

    def self.get(username)
      user = @@database.get("users", {username: username})[0]

      {
        id: user[:id],
        username: user[:username],
        bio: user[:bio]
      }
    end

    def self.authenticate(params)
      user = @@database.get("users", {username: params[:username]})[0]

      if user[:password] == params[:password]
        return {
          id: user[:id],
          username: user[:username],
          bio: user[:bio]
        }
      end

      nil
    end
    
    def self.post(params)
      @@database.add("posts", params)
    end

    def self.comment(params)
      @@database.add("comments", params)
    end

    def self.remove_post(post_id)
      @@database.remove("posts", post_id)
    end

    def self.remove_comment(comment_id)
      @@database.remove("comments", comment_id)
    end
  end

  class API < Sinatra::Base
    register Sinatra::SessionAuth

    configure do
      set :sessions, true
      set :session_secret, 'super complicated secret'
      set :database, App::DB.new
      set :authenticate, Proc.new { |params, session| session[:user] = App::User.authenticate(params) }    
    end
    
    App::User.connect_db(database)

    before do
      content_type 'application/json'
    end

    get "/profile" do
      authorize! do
        App::User.get(params[:username]).to_json
      end
    end

    get "/posts" do
      authorize! do
        settings.database.get("posts").to_json
      end
    end

    post "/posts" do
      authorize! do
        params[:user_id] = session[:user][:id].to_i
        return [201, {message: "Post created"}.to_json] if App::User.post(params)

        [500, {message: "Unable to create post"}.to_json]
      end
    end

    delete "/posts" do
      authorize! do
        if App::User.remove_post(params[:post_id].to_i)
          return [201, {message: "Post deleted"}.to_json]
        end

        [500, {message: "Unable to delete post"}.to_json]
      end
    end

    get "/comments" do
      authorize! do
        settings.database.get("comments", {post_id: params[:post_id].to_i}).to_json
      end
    end

    post "/comments" do
      authorize! do
        return [201, {message: "Comment created"}.to_json] if App::User.comment(params)

        [500, {message: "Unable to create comment"}.to_json]
      end
    end

    delete "/comments" do
      authorize! do
        if App::User.remove_comment(params[:comment_id].to_i)
          return [201, {message: "Comment deleted"}.to_json]
        end

        [500, {message: "Unable to delete comment"}.to_json]
      end
    end
  end
end

App.start!