# Faker helps you generate realistic test data, and populate
# your database with more than a couple of records while you're
# doing development.

require 'faker'
require 'json'
require 'open-uri'

# Ensure Faker generates unique data by resetting its seed
Faker::UniqueGenerator.clear

# Load random residential addresses
residential_address_pool = JSON.parse(File.read('db/Random_Residential_Addresses.json')).shuffle

# Open a file to write the user credentials
File.open('tmp/dev_user_passwords.txt', 'w') do |file|
  avatars_dir = Rails.root.join('lib', 'seeds', 'avatars')

  # Creating a bunch of Amigo records
  5.times do |i|
    password = Faker::Internet.password(min_length: 12, max_length: 20, mix_case: true, special_characters: true)
    amigo = Amigo.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      user_name: Faker::Internet.username(specifier: 8..16),
      email: Faker::Internet.email,
      secondary_email: Faker::Internet.email,
      password: password,
      password_confirmation: password,
      phone_1: Faker::PhoneNumber.phone_number_with_country_code,
      phone_2: Faker::PhoneNumber.phone_number_with_country_code,
      confirmed_at: Time.current
    )

    # Write the user credentials to the file
    file.puts "Amigo #{i + 1}:"
    file.puts "Username: #{amigo.user_name}"
    file.puts "Email: #{amigo.email}"
    file.puts "Password: #{password}"
    file.puts "\n"

    begin
      amigo.save!
    rescue ActiveRecord::RecordInvalid => e
    end

    # Sequential avatar assignment
    num_avatars = 15 #assuming that thefre are 15 avatars available.
    file_name = "avatar#{i % num_avatars + 1}.svg"
    file_path = avatars_dir.join(file_name)

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
    rescue => e
      puts "AmigoDetail could not be saved: #{e.message}"
    end

    # Assign a random address to amigo, popping it off the array
    # to avoid duplicates
    1.times do |j|
      address = residential_address_pool.pop
      amigo_location = AmigoLocation.new(
        amigo: amigo,
        # ... set the address fields using the popped address ...
        address: address["address"].presence,
        room_no: address["room_no"].presence,
        floor: address["floor"].presence,
        street_number: address["street_number"],
        street_name: address["street_name"],
        apartment_suite_number: address["secondary_address"].presence,
        city_sublocality: address["city_sublocality"].presence,
        city: address["city"],
        state_province_subdivision: address["state_province_subdivision"],
        state_province: address["state_province"],
        state_province_short: address["state_province_short"],
        country: address["country"],
        country_short: address["country_short"],
        postal_code: address["postal_code"],
        postal_code_suffix: address["postal_code_suffix"].presence,
        post_box: address["post_box"].presence,
        latitude: address["latitude"].presence,
        longitude: address["longitude"].presence,
        time_zone: address["time_zone"].presence
      )

      begin
        amigo_location.save!
      rescue => e # Catches any StandardError
        puts "AmigoLocation could not be saved: #{e.message}"
      end
    end
  end
end

# Load random business addresses
business_address_pool = JSON.parse(File.read('db/Random_Business_Addresses.json')).shuffle

5.times do |k|
  debugger
  event_coordinator = Amigo.all.sample # Randomly pick an existing Amigo as the coordinator
  event = Event.new(
    event_name: Faker::Lorem.sentence(word_count: 3),
    event_type: ["Conference", "Seminar", "Workshop", "Concert", "Festival"].sample,
    event_date: Faker::Date.forward(days: 365), # Random date within the next year
    event_time: Faker::Time.forward(days: 365, period: :evening),
    event_speakers_performers: Array.new(3) { Faker::Name.name },
    coordinator: event_coordinator
  )

  debugger

  if event.save
    puts "Event #{k + 1} created: #{event.event_name}"

    # Assign a random business address to event_location
    address = business_address_pool.pop
    event_location = EventLocation.new(
      # ... set the address fields using the popped address ...
      # amigo_id: amigo.id,
      business_name: address["business_name"],
      business_phone: address["phone"],
      address: address["address"].presence,
      room_no: address["room_no"].presence,
      floor: address["floor"].presence,
      street_number: address["street_number"],
      street_name: address["street_name"],
      apartment_suite_number: address["apartment_suite_number"].presence,
      city_sublocality: address["city_sublocality"].presence,
      city: address["city"],
      state_province_subdivision: address["state_province_subdivision"].presence,
      state_province: address["state_province"],
      state_province_short: address["state_province_short"],
      country: address["country"],
      country_short: address["country_short"],
      postal_code: address["postal_code"],
      postal_code_suffix: address["postal_code_suffix"].presence,
      post_box: address["postal_code"].presence,
      latitude: address["latitude"].presence,
      longitude: address["longitude"].presence,
      time_zone: address["time_zone"].presence
    )

    if event_location.save
      puts "EventLocation for Event #{k + 1} created: #{event_location.address}"

      event_location_connector = EventLocationConnector.new(event: event, event_location: event_location)
      if event_location_connector.save
        puts "EventLocationConnector created for Event #{k + 1}"
      else
        puts "EventLocationConnector could not be created: #{event_location_connector.errors.full_messages.join(", ")}"
      end
    else
      puts "EventLocation could not be created: #{event_location.errors.full_messages.join(", ")}"
    end

    # Add random participants to the event
    number_of_participants = rand(3..7) # Random number of participants
    number_of_participants.times do |l|
      participant = Amigo.all.sample
      event_participant = EventParticipant.new(
        event: event,
        amigo: participant
      )
      if event_participant.save
        puts "Participant #{participant.user_name} added to Event #{event.event_name}"
      else
        puts "Could not add participant: #{event_participant.errors.full_messages.join(", ")}"
      end
    end
  else
    puts "Event could not be created: #{event.errors.full_messages.join(", ")}"
  end
end

puts "#{Amigo.count} amigos created"
puts "#{AmigoLocation.count} amigo locations created"
puts "#{AmigoDetail.count} amigo details created"
puts "#{Event.count} events created"
puts "#{EventLocation.count} event locations created"
puts "#{EventParticipant.count} event participants created"
puts "#{EventLocationConnector.count} event location connectors created"
puts 'User passwords stored in tmp/dev_user_passwords.txt'