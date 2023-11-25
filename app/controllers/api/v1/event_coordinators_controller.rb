class Api::V1::EventCoordinatorsController < ApplicationController
  before_action :set_event
  before_action :set_event_coordinator, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/event_coordinators
  def index
    @event_coordinators = @event.event_coordinators
    render json: @event_coordinators
  end

  # GET /api/v1/events/:event_id/event_coordinators/:id
  def show
    render json: @event_coordinator
  end

  # POST /api/v1/events/:event_id/event_coordinators
  def create
    @event_coordinator = @event.event_coordinators.build(event_coordinator_params)

    if @event_coordinator.save
      render json: @event_coordinator, status: :created
    else
      render json: @event_coordinator.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/events/:event_id/event_coordinators/:id
  def update
    if @event_coordinator.update(event_coordinator_params)
      render json: @event_coordinator
    else
      render json: @event_coordinator.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_coordinators/:id
  def destroy
    @event_coordinator.destroy
    head :no_content
  end

  def locations_of_host
    coordinator = EventCoordinator.find(params[:id])
    @locations = coordinator.coordinated_locations
  
    render 'locations_of_host'
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_coordinator
    @event_coordinator = @event.event_coordinators.find(params[:id])
  end

  def event_coordinator_params
    params.require(:event_coordinator).permit(:amigo_id, :is_active)
  end
end