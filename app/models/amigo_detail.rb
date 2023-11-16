class AmigoDetail < ApplicationRecord
  belongs_to :amigo
  before_validation :remove_code_from_personal_bio

  validates :personal_bio, length: { maximum: 650 }

  private

  def remove_code_from_personal_bio
    self.personal_bio = Sanitize.fragment(self.personal_bio)
  end
end
