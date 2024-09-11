class LoginActivity < ApplicationRecord
  # Associates the login activity with an Amigo (user)
  belongs_to :amigo, optional: true

  # Fields for tracking activity (you can add these in your migration)
  # t.inet :ip_address       # To track the IP address of the login attempt
  # t.string :user_agent     # To track the browser or device information
  # t.boolean :successful    # To track if the login attempt was successful
  # t.timestamps             # To store the time of the login activity
end