# app/lib/custom_failure_app.rb
class CustomFailureApp < Devise::FailureApp
    def respond
      if request.controller_class.to_s.start_with?('Api::')
        json_api_error_response
      else
        super
      end
    end
  
    private
  
    def json_api_error_response
      self.status = 401
      self.content_type = 'application/json'
      self.response_body = { error: "Authentication failed." }.to_json
    end
  end    