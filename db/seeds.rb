# Faker helps you generate realistic test data, and populate
# your database with more than a couple of records while you're
# doing development.

require 'faker'
require 'json'

# Ensure Faker generates unique data by resetting its seed
Faker::UniqueGenerator.clear

# Load addresses from JSON file and shuffle them
address_pool = JSON.parse(File.read('db/Random_Business_Addresses.json')).shuffle

# Open a file to write the user credentials
File.open('tmp/dev_user_passwords.txt', 'w') do |file|

  # Creating a bunch of Amigo records
  8.times do
    password = Faker::Internet.password(min_length: 12, max_length: 20, mix_case: true, special_characters: true)
    ActiveRecord::Base.transaction do
      amigo = Amigo.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        user_name: Faker::Internet.username(specifier: 8..16),
        email: Faker::Internet.email,
        secondary_email: Faker::Internet.email,
        password: password,
        password_confirmation: password,
        phone_1: Faker::PhoneNumber.unique.cell_phone,
        phone_2: Faker::PhoneNumber.unique.cell_phone,
        date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 100),
        member_in_good_standing: [true, false].sample,
        available_to_host: [true, false].sample,
        willing_to_donate: [true, false].sample,
        personal_bio: Faker::Lorem.paragraph(sentence_count: 2),
        confirmed_at: Time.current
      )
        puts "Phone 1: #{:phone_1}"
        puts "Phone 2: #{:phone_2}"
        puts "Normalized Phone 1: #{Phonelib.parse(:phone_1).e164}"
        puts "Normalized Phone 2: #{Phonelib.parse(:phone_2).e164}"

        # Assign a random address to amigo, popping it off the array
        # to avoid duplicates
        2.times do
          address = address_pool.pop
          AmigoLocation.create!(
            amigo: amigo,
            # ... set the address fields using the popped address ...
            address: address["address"],
            address_type: address["address_type"],
            building: address["building"],
            floor: address["floor"],
            street_number: address["street_number"],
            street_name: address["street_name"],
            street_predirection: address["street_predirection"],
            street_suffix: address["street_suffix"],
            street_postdirection: address["street_postdirection"],
            apartment_number: address["apartment_number"], 
            city: address["city"],
            county: address["county"],
            state_abbreviation: address["state_abbreviation"],
            country_code: address["country_code"],
            postal_code: address["postal_code"],
            plus4_code: address["plus4_code"],
            latitude: address["latitude"],
            longitude: address["longitude"],
            time_zone: address["time_zone"],
            congressional_district: address["congressional_district"]
          )
        end

      # Write the user credentials to the file
      file.puts "Amigo #{i + 1}:"
      file.puts "Username: #{amigo.user_name}"
      file.puts "Email: #{amigo.email}"
      file.puts "Password: #{password}"
      file.puts "\n"
    end
  end
end

puts "#{Amigo.count} amigos created"
puts "#{AmigoLocation.count} amigo locations created"
puts 'User passwords stored in tmp/dev_user_passwords.txt'