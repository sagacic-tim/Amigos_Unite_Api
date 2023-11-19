class LoginActivity < ApplicationRecord
  # If only associated with Amigo
  belongs_to :amigo, optional: true
end

# class LoginActivity < ApplicationRecord
#   # Keeping it polymorphic for associating with multiple models
#   # like User, Admin, etc.
#   belongs_to :user, polymorphic: true, optional: true
# end