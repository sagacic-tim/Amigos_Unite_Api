class Api::V1::EventAmigoConnectorsController < ApplicationController
  before_action :authenticate_amigo!  # Ensure user is logged in
  before_action :set_event
  before_action :set_event_amigo_connector, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/event_amigo_connectors
  def index
    @event_amigo_connectors = @event.event_amigo_connectors
    render :index
  end

  # GET /api/v1/events/:event_id/event_amigo_connectors/:id
  def show
    render :show
  end

  # POST /api/v1/events/:event_id/event_amigo_connectors
  def create
    @event_amigo_connector = @event.event_amigo_connectors.new(event_amigo_connector_params)
    if authorized_to_assign?
      if @event_amigo_connector.save
        render :create, status: :created
      else
        render json: @event_amigo_connector.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # PATCH/PUT /api/v1/events/:event_id/event_amigo_connectors/:id
  def update
    if authorized_to_assign?
      if @event_amigo_connector.update(event_amigo_connector_params)
        render :update
      else
        render json: @event_amigo_connector.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # DELETE /api/v1/events/:event_id/event_amigo_connectors/:id
  def destroy
    if authorized_to_remove?
      @event_amigo_connector.destroy
      render :destroy
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  private

  def set_event
    @event = Event.find_by(id: params[:event_id])
    render json: { error: 'Event not found' }, status: :not_found unless @event
  end

  def set_event_amigo_connector
    @event_amigo_connector = @event.event_amigo_connectors.find_by(id: params[:id])
    render json: { error: 'Event Amigo Connector not found' }, status: :not_found unless @event_amigo_connector
  end

  def authorized_to_assign?
    Rails.logger.debug "Lead: #{lead}, Assistant: #{assistant}, Current Amigo: #{is_current_amigo}"
    current_amigo.lead_coordinator_for?(@event) || current_amigo.assistant_coordinator_for?(@event) ||
    current_amigo.id == params[:event_amigo_connector][:amigo_id].to_i
  end

  def authorized_to_remove?
    Rails.logger.debug "Is Current Amigo: #{is_current_amigo}, Lead: #{lead}, Assistant: #{assistant}"
    current_amigo.id == @event_amigo_connector.amigo_id ||
    current_amigo.lead_coordinator_for?(@event) ||
    current_amigo.assistant_coordinator_for?(@event)
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  def event_amigo_connector_params
    params.require(:event_amigo_connector).permit(
      :amigo_id,
      :role)
  end
end