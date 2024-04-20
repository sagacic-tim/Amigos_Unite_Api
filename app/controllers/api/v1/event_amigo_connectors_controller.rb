class EventAmigoConnectorsController < ApplicationController
  before_action :set_event
  before_action :authenticate_amigo!  # Ensure user is logged in
  before_action :set_event_amigo_connector, only: [:show, :remove_participant, :update, :destroy]

  # POST /api/v1/events/:event_id/event_amigo_connectors
  def create
    @event_amigo_connector = @event.event_amigo_connectors.new(event_amigo_connector_params)

    if authorized_to_assign?
      if @event_amigo_connector.save
        render :create, status: :created, location: api_v1_event_event_amigo_connector_path(@event, @event_amigo_connector)
      else
        render json: @event_amigo_connector.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # GET /api/v1/events/:event_id/event_amigo_connectors/:id
  def show
    render :show
  end

  # DELETE /api/v1/events/:event_id/event_amigo_connectors/:id
  def remove_participant
    if authorized_to_remove?
      @event_amigo_connector.destroy
      head :no_content
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_amigo_connector
    @event_amigo_connector = EventAmigoConnector.find(params[:id])
  end

  def event_amigo_connector_params
    params.require(:event_amigo_connector).permit(:amigo_id, :role)
  end

  def authorized_to_assign?
    current_amigo.lead_coordinator_for?(@event) || current_amigo.assistant_coordinator_for?(@event) ||
    current_amigo.id == params[:event_amigo_connector][:amigo_id].to_i
  end

  def authorized_to_remove?
    current_amigo.id == @event_amigo_connector.amigo_id ||
    current_amigo.lead_coordinator_for?(@event) ||
    current_amigo.assistant_coordinator_for?(@event)
  end
end