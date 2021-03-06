require 'sinatra/base'
require 'json'

module Sinatra
  module SessionAuth
    module Helpers
      def authorized?
        session[:logged_in] && session[:user]
      end

      def authorize!
        return [403, {message: "You must be logged in to access this."}.to_json] unless authorized?

        yield
      end

      def logout!
        session[:logged_in] = false
        session[:user] = nil
      end
    end

    def self.registered(app)
      app.helpers SessionAuth::Helpers

      app.post "/logout" do
        logout!
      end
      
      app.post "/login" do
        settings.authenticate params, session
        session[:logged_in] = true
        return [200, {message: "Access granted"}.to_json] if authorized?

        [401, {message: "Incorrect credentials"}.to_json]
      end
    end
  end

  register SessionAuth
end