class Api::V1::TestController < ApplicationController
  # Skip authentication for the test action
  skip_before_action :authenticate_amigo!, only: [:index]

  def index
    render json: { message: 'API is working' }, status: :ok
  end
end