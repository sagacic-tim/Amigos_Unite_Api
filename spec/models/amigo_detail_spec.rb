# spec/models/amigo_detail_spec.rb
RSpec.describe AmigoDetail, type: :model do
  let(:amigo) { create(:amigo) }

  it "strips scripts" do
    d = build(:amigo_detail, amigo:, personal_bio: "Hi<script>alert(1)</script>")
    expect { d.valid? }.to change { d.personal_bio }.from("Hi<script>alert(1)</script>").to("Hi")
  end

  it "preserves allowed inline tags (b/i) if configured" do
    d = build(:amigo_detail, amigo:, personal_bio: "Hello <b>world</b> <i>friend</i>")
    d.valid?
    expect(d.personal_bio).to eq("Hello <b>world</b> <i>friend</i>")
  end
end
