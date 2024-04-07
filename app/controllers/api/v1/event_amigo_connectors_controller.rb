class Api::V1::EventAmigoConnectorsController < ApplicationController
  before_action :set_event
  before_action :set_event_amigo_connector, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/event_amigo_connectors
  def index
    @event_amigo_connectors = @event.event_amigo_connectors.includes(:amigo)
    render json: @event_amigo_connectors, include: :amigo
  end

  # GET /api/v1/events/:event_id/event_amigo_connectors/:id
  def show
    render json: @event_amigo_connector
  end

  # POST /api/v1/events/:event_id/event_amigo_connectors
  def create
    @event_amigo_connector = @event.event_amigo_connectors.new(event_amigo_connector_params)

    if @event_amigo_connector.save
      render json: @event_amigo_connector, status: :created
    else
      render json: @event_amigo_connector.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/events/:event_id/event_amigo_connectors/:id
  def update
    if @event_amigo_connector.update(event_amigo_connector_params)
      render json: @event_amigo_connector
    else
      render json: @event_amigo_connector.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_amigo_connectors/:id
  def destroy
    @event_amigo_connector.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_amigo_connector
    @event_amigo_connector = @event.event_amigo_connectors.find(params[:id])
  end

  def event_amigo_connector_params
    params.require(:event_amigo_connector).permit(:amigo_id, :role)
  end
end