# app/controllers/concerns/error_handling.rb

module ErrorHandling
    extend ActiveSupport::Concern
  
    included do
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    end
  
    private
  
    def record_not_found(exception)
      render json: { error: exception.message }, status: :not_found
    end
  
    def record_invalid(exception)
      render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
    end
end