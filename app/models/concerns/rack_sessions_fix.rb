module RackSessionsFix
  extend ActiveSupport::Concern

  class FakeRackSession < Hash
    def enabled?
      false
    end

    def destroy
      # nothing to add here
    end
  end

  included do
    before_action :set_fake_session
    before_action :set_session_for_devise
  end

  private

  def set_fake_session
    request.env['rack.session'] ||= FakeRackSession.new
  end

  def set_session_for_devise
    request.session_options[:skip] = true
  end
end