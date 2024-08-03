module Api
  module V1
    class AmigosController < ApplicationController
      before_action :authenticate_amigo!, only: [:show, :update, :destroy]
      before_action :set_amigo, only: [:show, :update, :destroy]
      before_action :authorize_amigo!, only: [:destroy]
      helper_method :current_amigo

      def index
        Rails.logger.info("Is Amigo signed in? #{amigo_signed_in?}")
        @amigos = Amigo.all
        render json: @amigos, status: :ok
      end
      
      def show
        render json: @amigo, status: :ok
      end

      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))
        
        if params[:amigo][:avatar]
          @amigo.attach_avatar_by_identifier(params[:amigo][:avatar])
        end
      
        if @amigo.save
          render json: @amigo, status: :created
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      def update
        if @amigo.update(amigo_params)
          render json: @amigo, status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      def destroy
        if @amigo.destroy
          render json: { message: 'Amigo deleted successfully' }, status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      private

      def set_amigo
        @amigo = Amigo.find(params[:id])
      end

      def authorize_amigo!
        unless current_amigo == @amigo
          render json: { error: 'Not authorized' }, status: :unauthorized
        end
      end

      def amigo_params
        params.require(:amigo).permit(:first_name, :last_name, :user_name, :email, :secondary_email, :phone_1, :phone_2, :password, :avatar)
      end
    end
  end
end