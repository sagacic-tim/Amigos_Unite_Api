class AmigoDetail < ApplicationRecord
  belongs_to :amigo
  before_validation :remove_code_from_personal_bio
  before_validation :normalize_boolean_fields
  before_validation :remove_code_from_personal_bio
  before_validation :convert_date_of_birth
  before_validation :validate_date_of_birth

  validates :personal_bio, length: { maximum: 650 }

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

  def convert_date_of_birth
    Rails.logger.debug { "\"date_of_birth\", at top line of convert_date_of_birth = #{self.date_of_birth.inspect}" }
    return unless date_of_birth.present? && date_of_birth.is_a?(String)
    Rails.logger.debug { "\"date_of_birth\", convert_date_of_birth return = #{self.date_of_birth.inspect}" }
  
    parsed_date = Date.strptime(date_of_birth, '%m/%d/%Y') rescue nil
    if parsed_date
      Rails.logger.debug { "date_of_birth immediately before conversion = #{date_of_birth.inspect}" }
      self.date_of_birth = parsed_date
      Rails.logger.debug { "date_of_birth immediately after conversion = #{date_of_birth.inspect}" }
    else
      errors.add(:date_of_birth, 'is in an unrecognized format')
    end
  end

  def validate_date_of_birth
    Rails.logger.debug { "\"date_of_birth\": before validataion = #{date_of_birth.inspect}" }
    if date_of_birth.present?
      unless date_of_birth.is_a?(Date) || date_of_birth.match(/\A\d{4}-\d{2}-\d{2}\z/)
        errors.add(:date_of_birth, 'must be in YYYY-MM-DD format')
      end
  
      # Example range check: no more than 120 years ago, no later than today
      if date_of_birth < Date.today - 120.years || date_of_birth > Date.today
        errors.add(:date_of_birth, 'is not in a reasonable range')
      end
    else
      errors.add(:date_of_birth, 'is required')
    end
  end
end