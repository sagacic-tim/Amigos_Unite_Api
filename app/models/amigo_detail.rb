class AmigoDetail < ApplicationRecord
  belongs_to :amigo
  before_validation :remove_code_from_personal_bio
  before_validation :normalize_boolean_fields
  before_validation :remove_code_from_personal_bio
  before_validation :convert_date_of_birth

  validates :personal_bio, length: { maximum: 650 }
  validate :date_of_birth_format

  private

  def remove_code_from_personal_bio
    self.personal_bio = Sanitize.fragment(self.personal_bio)
  end

  # Convert various representations of boolean values to true/false
  def normalize_boolean_fields
    self.member_in_good_standing = to_boolean(member_in_good_standing)
    self.available_to_host = to_boolean(available_to_host)
    self.willing_to_help = to_boolean(willing_to_help)
    self.willing_to_donate = to_boolean(willing_to_donate)
  end

  # Convert input to a boolean value
  def to_boolean(value)
    return true if value.to_s.downcase.in?(['yes', 'true', '1'])
    return false if value.to_s.downcase.in?(['no', 'false', '0', ''])
    nil
  end

  # Attempts to parse the date_of_birth from a string using multiple expected formats
  def convert_date_of_birth
    # Return immediately if date_of_birth is already a Date object or nil
    return if date_of_birth.is_a?(Date) || date_of_birth.nil?

    date_str = date_of_birth_before_type_cast
    # Define a list of expected date formats
    expected_formats = [
      '%m/%d/%Y', # MM/DD/YYYY
      '%d/%m/%Y', # DD/MM/YYYY
      '%Y-%m-%d', # YYYY/MM/DD
      '%Y-%m-%d', # YYYY-MM-DD
      '%d-%m-%Y', # DD-MM-YYYY
      '%d.%m.%Y', # DD.MM.YYYY
      '%d %B %Y', # DD MMMM YYYY
      '%B %d, %Y' # MMMM DD, YYYY
    ]

    # Special handling for 'YYYY年MM月DD日' format
    if date_str.match(/\A\d{4}年\d{1,2}月\d{1,2}日\z/)
      date_str = date_str.gsub(/[年月日]/, '年' => '/', '月' => '/', '日' => '')
      expected_formats << '%Y/%m/%d' # Ensure this format is tried for 'YYYY年MM月DD日'
    end

    # Try each format in sequence
    parsed_date = nil
    expected_formats.each do |format|
      begin
        parsed_date = Date.strptime(date_str, format)
        break if parsed_date # If parsing succeeds, stop trying more formats
      rescue ArgumentError
        # Ignore parsing errors and try the next format
      end
    end

    if parsed_date
      # If a valid date was parsed, set it
      self.date_of_birth = parsed_date
      Rails.logger.debug { "date_of_birth after assignment: #{date_of_birth.inspect}" }
    else
      # If none of the formats worked, add an error
      errors.add(:date_of_birth, 'is in an unrecognized format. Expected formats: M/DD/YYYY, DD/MM/YYYY, YYYY/MM/DD, YYYY-MM-DD, DD-MM-YYYY, DD.MM.YYYY, DD MMMM YYYY, MMMM DD, YYYY, YYYY年MM月DD日')
    end
  end

  # Ensure date_of_birth is a valid date object
  def date_of_birth_format
    errors.add(:date_of_birth, 'must be a valid date') unless date_of_birth.is_a?(Date)
  end

end