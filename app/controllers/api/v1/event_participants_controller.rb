class Api::V1::EventParticipantsController < ApplicationController
  before_action :set_event
  before_action :set_event_participant, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/event_participants
  def index
    @event_participants = @event.event_participants
    render json: @event_participants
  end

  # GET /api/v1/events/:event_id/event_participants/:id
  def show
    render json: @event_participant
  end

  # POST /api/v1/events/:event_id/event_participants
  def create
    @event_participant = @event.event_participants.new(event_participant_params)

    if @event_participant.save
      render json: @event_participant, status: :created
    else
      render json: @event_participant.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/events/:event_id/event_participants/:id
  def update
    if @event_participant.update(event_participant_params)
      render json: @event_participant
    else
      render json: @event_participant.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_participants/:id
  def destroy
    @event_participant.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_participant
    @event_participant = @event.event_participants.find(params[:id])
  end

  def event_participant_params
    params.require(:event_participant).permit(:amigo_id)
  end
end