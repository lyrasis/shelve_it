class ShelveItController < ApplicationController

  set_access_control  "update_container_record" => [:update],
                      "update_location_record"  => [:update],
                      "view_repository"         => [:update]

  def update
    container_barcode = params[:container_barcode]
    location_barcode  = params[:location_barcode]

    container_uri = container_barcode # see top_containers_controller#perform_search
    location_uri  = location_barcode  #
    location_data = { container_uri => location_uri }

    response = JSONModel::HTTP.post_json(URI(shelve_it_uri), location_data.to_json)
    result   = ASUtils.json_parse(response.body) rescue nil

    if response.code =~ /^(4)/
      flash[:error] = (result || response.message)
    elsif response.code =~ /^5/
      flash[:error] = response.message
    else
      flash[:info] = result
    end

    redirect_to controller: :welcome, action: :index
  end

  private

  def shelve_it_uri
    repo_id     = session[:repo_id]
    update_path = 'top_containers/bulk/locations'
    "#{JSONModel::HTTP.backend_url}/repositories/#{repo_id}/#{update_path}"
  end

end