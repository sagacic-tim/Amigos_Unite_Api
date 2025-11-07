# spec/requests/amigo_details_spec.rb
RSpec.describe "AmigoDetails", type: :request do
  let(:amigo) { create(:amigo_with_jwt) } # helper that signs in / sets auth headers

  it "sanitizes on update" do
    detail = create(:amigo_detail, amigo:, personal_bio: nil)
    patch api_v1_amigo_amigo_detail_path(amigo),
      params: { amigo_detail: { personal_bio: %(<img src=x onerror=alert(1)>) } },
      headers: auth_headers_for(amigo)
    expect(response).to have_http_status(:ok)
    expect(detail.reload.personal_bio).to eq("") # or be invalid if you enforce non-empty
  end
end
