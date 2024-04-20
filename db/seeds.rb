require 'faker'
require 'json'
require 'open-uri'

Faker::UniqueGenerator.clear
residential_address_pool = JSON.parse(File.read('db/random_residential_addresses.json')).shuffle
business_address_pool = JSON.parse(File.read('db/random_business_addresses.json')).shuffle
avatars_dir = Rails.root.join('lib', 'seeds', 'avatars')
password_file = File.open('tmp/dev_user_passwords.txt', 'w')

10.times do |i|
  begin
    password = Faker::Internet.password(min_length: 12, max_length: 20)
    amigo = Amigo.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      user_name: Faker::Internet.username,
      email: Faker::Internet.email,
      secondary_email: Faker::Internet.email,
      phone_1: Faker::PhoneNumber.phone_number_with_country_code,
      phone_2: Faker::PhoneNumber.phone_number_with_country_code,
      password: password,
      password_confirmation: password,
      confirmed_at: Time.current
    )
    puts "Amigo #{i + 1} created"

    if amigo.persisted?
      password_file.puts("Amigo #{i + 1}: Username: #{amigo.user_name}, Email: #{amigo.email}, Password: #{password}")
      file_name = "avatar#{i % 15 + 1}.svg"
      file_path = avatars_dir.join(file_name)
      
      if File.exist?(file_path)
        File.open(file_path) do |file|
          amigo.avatar.attach(io: file, filename: file_name)
          puts "Avatar #{file_name} attached to Amigo #{i + 1}"
        end
      end

      AmigoDetail.create!(
        amigo: amigo,
        member_in_good_standing: [true, false].sample,
        available_to_host: [true, false].sample,
        willing_to_help: [true, false].sample,
        willing_to_donate: [true, false].sample,
        personal_bio: Faker::Lorem.paragraph(sentence_count: 2),
        date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 100)
      )
      puts "AmigoDetail #{i + 1} created"
      
      amigo_address = residential_address_pool.pop
      AmigoLocation.create!(
        amigo: amigo,
        address: amigo_address["address"],
        room_no: amigo_address["room_no"],
        floor: amigo_address["floor"],
        street_number: amigo_address["street_number"],
        street_name: amigo_address["street_name"],
        apartment_suite_number: amigo_address["secondary_address"],
        city_sublocality: amigo_address["city_sublocality"],
        city: amigo_address["city"],
        state_province_subdivision: amigo_address["state_province_subdivision"],
        state_province: amigo_address["state_province"],
        state_province_short: amigo_address["state_province_short"],
        country: amigo_address["country"],
        country_short: amigo_address["country_short"],
        postal_code: amigo_address["postal_code"],
        postal_code_suffix: amigo_address["postal_code_suffix"],
        post_box: amigo_address["post_box"],
        latitude: amigo_address["latitude"],
        longitude: amigo_address["longitude"],
        time_zone: amigo_address["time_zone"]
      )
      puts "AmigoLocation #{i + 1} created"
    else
      puts "Failed to create Amigo #{i + 1}"
    end
  rescue StandardError => e
    puts "Exception when creating Amigo #{i + 1}: #{e.message}"
  end
end

password_file.close unless password_file.closed?

5.times do |k|
  begin
    lead_coordinator = Amigo.order(Arel.sql('RANDOM()')).first
    event = Event.create!(
      event_name: Faker::Lorem.sentence(word_count: 3),
      event_type: ["Conference", "Seminar", "Workshop", "Concert", "Festival"].sample,
      event_date: Faker::Date.forward(days: 365),
      event_time: Faker::Time.forward(days: 365, period: :evening),
      lead_coordinator: lead_coordinator
    )

    puts "Event #{k + 1} created"
    event_address = business_address_pool.pop
    event_location = EventLocation.create!(
      business_name: event_address["business_name"],
      business_phone: event_address["phone"],
      address: event_address["address"],
      room_no: event_address["room_no"],
      floor: event_address["floor"],
      street_number: event_address["street_number"],
      street_name: event_address["street_name"],
      apartment_suite_number: event_address["apartment_suite_number"],
      city_sublocality: event_address["city_sublocality"],
      city: event_address["city"],
      state_province_subdivision: event_address["state_province_subdivision"],
      state_province: event_address["state_province"],
      state_province_short: event_address["state_province_short"],
      country: event_address["country"],
      country_short: event_address["country_short"],
      postal_code: event_address["postal_code"],
      postal_code_suffix: event_address["postal_code_suffix"],
      post_box: event_address["post_box"],
      latitude: event_address["latitude"],
      longitude: event_address["longitude"],
      time_zone: event_address["time_zone"]
    )
    if event_location.persisted?
      puts "Event Location created for Event ##{k + 1}"
      # Create EventLocationConnector for each event and location
      event_location_connector = EventLocationConnector.create!(
        event_id: event.id,
        event_location_id: event_location.id
      )
      if event_location_connector.persisted?
        puts "EventLocationConnector created for Event ##{k + 1}"
      else
        puts "EventLocationConnector created for Event ##{k + 1}"
      end

      num_participants = rand(3..10)
      participants = Amigo.where.not(id: lead_coordinator.id).sample(num_participants)
      num_assistant_coordinators = case num_participants
                                   when 8..10 then 3
                                   when 6..7 then 2
                                   when 3..5 then 1
                                   else 0
                                   end

      assistant_coordinators = participants.sample(num_assistant_coordinators)
      participants.each do |participant|
        role = assistant_coordinators.include?(participant) ? 'assistant_coordinator' : 'participant'
        connector = EventAmigoConnector.create!(
          event: event,
          amigo: participant,
          role: role
        )
        if connector.persisted?
          puts "Role #{role} assigned to #{participant.first_name} #{participant.last_name} for Event #{k + 1}."
        else
          puts "Failed to assign role #{role} to #{participant.first_name} #{participant.last_name}: #{connector.errors.full_messages.join(', ')}"
        end
      end
    else
      puts "Failed to create Event #{k + 1}"
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "Error during creation for Event #{k + 1}: #{e.message}"
  end
end

puts "Seed data creation complete!"
puts "#{Amigo.count} amigos created"
puts "#{AmigoLocation.count} amigo locations created"
puts "#{AmigoDetail.count} amigo details created"
puts "#{Event.count} events created"
puts "#{EventLocation.count} event locations created"
puts "#{EventAmigoConnector.count} event participants created"
puts "#{EventLocationConnector.count} event location connectors created"
puts 'User passwords stored in tmp/dev_user_passwords.txt'
puts 'Event Participant Roles:'
Event.includes(:lead_coordinator, event_amigo_connectors: :amigo).find_each do |event|
  puts "  The coordinators for Event: \"#{event.event_name}\" (ID: #{event.id}), are:"
  puts "    Lead Coordinator: #{event.lead_coordinator.first_name} #{event.lead_coordinator.last_name}, Amigo ID: #{event.lead_coordinator_id}"
  assistant_coordinators = event.event_amigo_connectors.where(role: 'assistant_coordinator')
  if assistant_coordinators.any?
    puts "      The Assistant Coordinators are:\n"
    assistant_coordinators.each do |connector|
      puts "        #{connector.amigo.first_name} #{connector.amigo.last_name}, Amigo ID: #{connector.amigo_id}"
    end
  else
    puts "      There are no Assistant Coordinators for this event"
  end
  puts "\n"
end