class Api::V1::AmigoDetailsController < ApplicationController
  params 
  def amigo_details_params
    params.require(:amigo_details).permit(:date_of_birth, :member_in_good_standing, :available_to_host, :willing_to_help, :willing_to_donate, :personal_bio)
  end
end
