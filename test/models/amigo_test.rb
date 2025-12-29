# test/models/amigo_test.rb
require "test_helper"

class AmigoTest < ActiveSupport::TestCase
  test "factory is valid" do
    amigo = build(:amigo)
    assert amigo.valid?, amigo.errors.full_messages.to_sentence
  end

  test "requires user_name" do
    amigo = build(:amigo, user_name: nil)
    assert_not amigo.valid?
    assert_includes amigo.errors[:user_name], "can't be blank"
  end

  test "requires email" do
    amigo = build(:amigo, email: nil)
    assert_not amigo.valid?
    assert_includes amigo.errors[:email], "can't be blank"
  end

  test "user_name is unique" do
    create(:amigo, user_name: "duplicate_name")
    duplicate = build(:amigo, user_name: "duplicate_name")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_name], "has already been taken"
  end
end
