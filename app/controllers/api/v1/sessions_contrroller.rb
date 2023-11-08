# app/controllers/api/v1/amigos/sessions_controller.rb
class Api::V1::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    if resource.persisted?
      sign_in(resource_name, resource)
      render 'api/v1/amigos/create' # This will use your jbuilder template
    else
      render 'api/v1/sessions/new' # This will use your jbuilder template for errors
    end
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  private

  # Notice the name of the method
  def respond_with(resource, _opts = {})
    render 'api/v1/amigos/create' # This will use your jbuilder template
  end

  def respond_to_on_destroy
    head :no_content
  end
end
