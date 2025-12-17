# app/controllers/api/v1/event_amigo_connectors_controller.rb
module Api
  module V1
    class EventAmigoConnectorsController < ApplicationController
      before_action :authenticate_amigo!
      before_action :set_event
      before_action :set_event_amigo_connector, only: [:show, :update, :destroy]
      before_action :set_target_amigo,          only: [:create, :update, :destroy]

      def index
        if params[:event_id].present?
          return unless @event  # set_event already rendered 404 if not found

          @event_amigo_connectors =
            @event.event_amigo_connectors.includes(:amigo)
        else
          @event_amigo_connectors =
            EventAmigoConnector.includes(:amigo, :event).all
        end

        render :index
      end

      def show
        render :show
      end

      # Allows “manager OR self-join”.
      def create
        return render json: { error: 'amigo_id is required' }, status: :unprocessable_entity unless @target_amigo

        can_manage = EventPolicy.new(current_amigo, @event).manage_connectors?
        self_join  = @target_amigo && current_amigo.id == @target_amigo.id
        return unauthorized! unless can_manage || self_join

        role = resolved_role || :participant
        @event_amigo_connector =
          @event.event_amigo_connectors.new(amigo: @target_amigo, role: role)

        if @event_amigo_connector.save
          render json: @event_amigo_connector, status: :created
        else
          render json: @event_amigo_connector.errors, status: :unprocessable_entity
        end
      end

      # Only role changes here; lead goes through TransferLead.
      def update
        target = @target_amigo || @event_amigo_connector&.amigo
        return render json: { error: 'Target not found' }, status: :unprocessable_entity unless target

        role_sym = resolved_role
        return render json: { error: 'Role param is required' }, status: :unprocessable_entity unless role_sym

        valid_roles = EventAmigoConnector.roles.keys.map!(&:to_sym)
        unless valid_roles.include?(role_sym)
          return render json: { error: "Invalid role. Allowed: #{valid_roles.join(', ')}" },
                        status: :unprocessable_entity
        end

        conn =
          if role_sym == :lead_coordinator
            Events::TransferLead.new.call(
              actor: current_amigo,
              event: @event,
              new_lead: target
            )
          else
            Events::ChangeRole.new.call(
              actor: current_amigo,
              event: @event,
              target: target,
              new_role: role_sym
            )
          end

        render json: conn, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Allows “manager OR self-remove”.
      def destroy
        can_manage = EventPolicy.new(current_amigo, @event).manage_connectors?

        connector =
          if @event_amigo_connector
            @event_amigo_connector
          elsif @target_amigo
            @event.event_amigo_connectors.find_by!(amigo_id: @target_amigo.id)
          else
            return render json: { error: 'Connector not found' }, status: :not_found
          end

        self_owner = current_amigo.id == connector.amigo_id
        return unauthorized! unless can_manage || self_owner

        connector.destroy!
        head :no_content
      end

      private

      def set_event
        return unless params[:event_id].present?

        @event = Event.find_by(id: params[:event_id])
        unless @event
          render json: { error: 'Event not found' }, status: :not_found
        end
      end

      def set_event_amigo_connector
        return unless @event

        @event_amigo_connector =
          @event.event_amigo_connectors.find_by(id: params[:id])

        unless @event_amigo_connector
          render json: { error: 'Event Amigo Connector not found' },
                 status: :not_found
        end
      end

      def set_target_amigo
        amigo_id = params.dig(:event_amigo_connector, :amigo_id) || params[:amigo_id]
        @target_amigo = Amigo.find_by(id: amigo_id) if amigo_id.present?
      end

      def resolved_role
        raw = params.dig(:event_amigo_connector, :role) || params[:role]
        raw.present? ? raw.to_s.strip.downcase.to_sym : nil
      end

      def event_amigo_connector_params
        params.require(:event_amigo_connector).permit(:amigo_id, :role)
      end

      def unauthorized!
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
