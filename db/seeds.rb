require 'faker'
require 'json'

Faker::UniqueGenerator.clear

residential_address_pool = JSON.parse(File.read('db/random_residential_addresses.json')).shuffle
business_address_pool = JSON.parse(File.read('db/random_business_addresses.json')).shuffle
avatars_dir = Rails.root.join('lib', 'seeds', 'avatars')
password_file = File.open('tmp/dev_user_passwords.txt', 'w')

# Create Amigos with AmigoDetails and AmigoLocations
10.times do |i|
  begin
    password = Faker::Internet.password(min_length: 12, max_length: 20)
    email = Faker::Internet.unique.email
    user_name = Faker::Internet.unique.username

    amigo = Amigo.find_or_create_by!(email: email) do |a|
      a.first_name = Faker::Name.first_name
      a.last_name = Faker::Name.last_name
      a.user_name = user_name
      a.secondary_email = Faker::Internet.email
      a.phone_1 = Faker::PhoneNumber.phone_number_with_country_code
      a.phone_2 = Faker::PhoneNumber.phone_number_with_country_code
      a.password = password
      a.password_confirmation = password
      a.confirmed_at = Time.current
    end

    password_file.puts("Amigo #{i + 1}: Username: #{amigo.user_name}, Email: #{amigo.email}, Password: #{password}")

    avatar_file = avatars_dir.join("avatar#{i % 15 + 1}.svg")
    amigo.avatar.attach(io: File.open(avatar_file), filename: avatar_file.basename.to_s) if File.exist?(avatar_file)

    AmigoDetail.find_or_create_by!(amigo: amigo) do |detail|
      detail.member_in_good_standing = [true, false].sample
      detail.available_to_host = [true, false].sample
      detail.willing_to_help = [true, false].sample
      detail.willing_to_donate = [true, false].sample
      detail.personal_bio = Faker::Lorem.paragraph(sentence_count: 2)
      detail.date_of_birth = Faker::Date.birthday(min_age: 18, max_age: 100)
    end

    # Create AmigoLocation from partial address and let Geocoder fill it in
    address = residential_address_pool.pop
    location = AmigoLocation.new(
      amigo: amigo,
      street_number: address["street_number"],
      street_name: address["street_name"],
      city: address["city"],
      state_province: address["state_province"],
      country: address["country"],
      postal_code: address["postal_code"]
    )
    location.save!
  rescue => e
    puts "❌ Failed to create Amigo #{i + 1}: #{e.message}"
  end
end

password_file.close

# Create Events with EventLocations
5.times do |i|
  begin
    lead = Amigo.order(Arel.sql("RANDOM()")).first
    event = Event.create!(
      event_name: Faker::Lorem.sentence(word_count: 3),
      event_type: %w[Conference Seminar Workshop Concert Festival].sample,
      event_date: Faker::Date.forward(days: 365),
      event_time: Faker::Time.forward(days: 365, period: :evening),
      lead_coordinator: lead
    )

    address = business_address_pool.pop
    location = EventLocation.new(
      business_name: address["business_name"],
      street_number: address["street_number"],
      street_name: address["street_name"],
      city: address["city"],
      state_province: address["state_province"],
      country: address["country"],
      postal_code: address["postal_code"]
    )
    location.save!

    EventLocationConnector.create!(event: event, event_location: location)

    # Add EventAmigoConnectors
    participants = Amigo.where.not(id: lead.id).sample(rand(3..10))
    assistants = participants.sample(rand(0..[3, participants.size].min))

    participants.each do |p|
      role = assistants.include?(p) ? 'assistant_coordinator' : 'participant'
      EventAmigoConnector.find_or_create_by!(event: event, amigo: p, role: role)
    end
  rescue => e
    puts "❌ Failed to create Event #{i + 1}: #{e.message}"
  end
end

puts "✅ Seeding complete!"
puts "#{Amigo.count} amigos"
puts "#{AmigoLocation.count} amigo locations"
puts "#{AmigoDetail.count} amigo details"
puts "#{Event.count} events"
puts "#{EventLocation.count} event locations"
puts "#{EventAmigoConnector.count} event participants"
puts "#{EventLocationConnector.count} event location connectors"
