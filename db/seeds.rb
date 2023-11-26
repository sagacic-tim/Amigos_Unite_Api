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
    num_avatars = 15 #assuming that thefre are 15 avatars available.
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
        room: address["room"].presence,
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

8.times do |k|
  event_coordinator = Amigo.all.sample # Randomly pick an existing Amigo as the coordinator
  event = Event.new(
    event_name: Faker::Lorem.sentence(word_count: 3),
    event_type: ["Conference", "Seminar", "Workshop", "Concert", "Festival"].sample,
    event_date: Faker::Date.forward(days: 365), # Random date within the next year
    event_time: Faker::Time.forward(days: 365, period: :evening),
    event_speakers_performers: Array.new(3) { Faker::Name.name },
    coordinator: event_coordinator
  )

  if event.save
    puts "Event #{k + 1} created: #{event.event_name}"

    # Assign a random business address to event_location
    address = business_address_pool.pop
    event_location = EventLocation.new(
      event: event,
      # ... set the address fields using the popped address ...
      business_name: address["business_name"]
      phone: address["phone"].presence
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

    if event_location.save
      puts "EventLocation for Event #{k + 1} created: #{event_location.address}"
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
puts 'User passwords stored in tmp/dev_user_passwords.txt'