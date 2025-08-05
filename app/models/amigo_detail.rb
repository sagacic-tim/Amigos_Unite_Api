class AmigoDetail < ApplicationRecord
  belongs_to :amigo

  before_validation :sanitize_personal_bio
  before_validation :normalize_boolean_fields
  before_validation :convert_date_of_birth

  validates :personal_bio, length: { maximum: 650 }
  validate :date_of_birth_format

  private

  # Sanitize HTML tags or unwanted characters from bio
  def sanitize_personal_bio
    self.personal_bio = Sanitize.fragment(personal_bio)
  end

  # Normalize input values to true/false/nil for boolean fields
  def normalize_boolean_fields
    %i[
      member_in_good_standing
      available_to_host
      willing_to_help
      willing_to_donate
    ].each do |field|
      self[field] = coerce_to_boolean(self[field])
    end
  end

  def coerce_to_boolean(value)
    case value.to_s.strip.downcase
    when 'true', 'yes', '1' then true
    when 'false', 'no', '0', '' then false
    else nil
    end
  end

  # Attempts to coerce date_of_birth to a proper Date object from various formats
  def convert_date_of_birth
    return if date_of_birth.is_a?(Date) || date_of_birth.nil?

    raw_input = date_of_birth_before_type_cast.to_s.strip

    # Handle Japanese-style date strings
    if raw_input.match(/\A\d{4}年\d{1,2}月\d{1,2}日\z/)
      raw_input = raw_input.gsub(/[年月日]/, '年' => '/', '月' => '/', '日' => '')
    end

    formats = [
      '%m/%d/%Y', '%d/%m/%Y', '%Y/%m/%d',
      '%Y-%m-%d', '%d-%m-%Y', '%d.%m.%Y',
      '%d %B %Y', '%B %d, %Y'
    ]

    parsed = formats.lazy.map do |fmt|
      begin
        Date.strptime(raw_input, fmt)
      rescue ArgumentError
        nil
      end
    end.find(&:present?)

    if parsed
      self.date_of_birth = parsed
      Rails.logger.debug "Parsed date_of_birth: #{date_of_birth.inspect}"
    else
      errors.add(:date_of_birth, 'is in an unrecognized format. Expected formats include MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, and others.')
    end
  end

  # Ensures final value is a valid Date object
  def date_of_birth_format
    errors.add(:date_of_birth, 'must be a valid date') unless date_of_birth.is_a?(Date)
  end
end
