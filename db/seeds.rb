# Faker helps you generate realistic test data, and populate
# your database with more than a couple of records while you're
# doing development.

require 'faker'
require 'json'
require 'open-uri'

# Ensure Faker generates unique data by resetting its seed
Faker::UniqueGenerator.clear

# Load addresses from JSON file and shuffle them
address_pool = JSON.parse(File.read('db/Random_Residential_Addresses.json')).shuffle

# Open a file to write the user credentials
File.open('tmp/dev_user_passwords.txt', 'w') do |file|
  avatars_dir = Rails.root.join('lib', 'seeds', 'avatars')
  num_avatars = 15  # Assuming there are 15 avatars in lib/seeds/avatars

  # Creating a bunch of Amigo records
  8.times do |i|
    password = Faker::Internet.password(min_length: 12, max_length: 20, mix_case: true, special_characters: true)
    amigo = Amigo.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      user_name: Faker::Internet.username(specifier: 8..16),
      email: Faker::Internet.email,
      secondary_email: Faker::Internet.email,
      password: password,
      password_confirmation: password,
      phone_1: Faker::PhoneNumber.unique.cell_phone,
      phone_2: Faker::PhoneNumber.unique.cell_phone,
      confirmed_at: Time.current
    )

    puts amigo.inspect

    # Write the user credentials to the file
    file.puts "Amigo #{i + 1}:"
    file.puts "Username: #{amigo.user_name}"
    file.puts "Email: #{amigo.email}"
    file.puts "Password: #{password}"
    file.puts "\n"

    begin
      amigo.save!
    rescue ActiveRecord::RecordInvalid => e
      puts e.record.errors.full_messages
    end

    # Sequential avatar assignment
    num_avatars = 15
    file_name = "avatar#{i % num_avatars + 1}.svg"
    file_path = avatars_dir.join(file_name)
    puts "Avatar file path = #{file_path}"

    if File.exist?(file_path)
      avatar_file = File.open(file_path)
      amigo.avatar.attach(io: avatar_file, filename: file_name)
      puts "Avatar #{file_name} attached to Amigo #{i + 1}"
      avatar_file.close
    end

    # Add amigo details
    amigo_detail = AmigoDetail.new(
      amigo: amigo,
      member_in_good_standing: [true, false].sample,
      available_to_host: [true, false].sample,
      willing_to_help: [true, false].sample,
      willing_to_donate: [true, false].sample,
      personal_bio: Faker::Lorem.paragraph(sentence_count: 2),
      date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 100)
    )

    begin
      amigo_detail.save!
      puts "AmigoDetail for Amigo #{i + 1} created"
      puts amigo_detail.inspect
    rescue => e
      puts "AmigoDetail could not be saved: #{e.message}"
    end

    # Assign a random address to amigo, popping it off the array
    # to avoid duplicates
    2.times do |j|
      address = address_pool.pop
      amigo_location = AmigoLocation.new(
        amigo: amigo,
        # ... set the address fields using the popped address ...
        building: address["building"].presence,
        floor: address["floor"].presence,
        street_number: address["street_number"],
        street_name: address["street_name"],
        street_predirection: address["street_predirection"].presence,
        street_suffix: address["street_suffix"].presence,
        street_postdirection: address["street_postdirection"].presence,
        apartment_suite_number: address["apartment_suite_number"].presence, 
        city: address["city"],
        state_abbreviation: address["state_abbreviation"],
        country_code: address["country_code"],
        postal_code: address["postal_code"]
      )

      begin
        amigo_location.save!
      rescue => e # Catches any StandardError
        puts "AmigoLocation could not be saved: #{e.message}"
      end
      puts "Address #{j + 1} for Amigo #{i + 1}"
    end
  end
end

puts "#{Amigo.count} amigos created"
puts "#{AmigoLocation.count} amigo locations created"
puts "#{AmigoDetail.count} amigo details created"
puts 'User passwords stored in tmp/dev_user_passwords.txt'