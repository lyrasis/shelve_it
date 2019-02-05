class ShelveItController < ApplicationController

  set_access_control  "update_container_record" => [:update],
                      "update_location_record"  => [:update],
                      "view_repository"         => [:update]

  def update
    container_barcode = params[:container_barcode]
    location_barcode  = params[:location_barcode]

    container = container_by_barcode(container_barcode)
    location  = location_by_barcode(location_barcode)

    if container && location
      shelve_it(container['uri'] => location['uri'])
    else
      bad = [container_barcode.strip, location_barcode.strip].compact.join(',')
      flash[:error] = "Error, check barcodes exist! #{bad}"
    end

    redirect_to controller: :welcome, action: :index
  end

  private

  def container_by_barcode(barcode)
    repo_id = session[:repo_id]
    path    = "/repositories/#{repo_id}/top_containers/barcodes/#{barcode}"
    JSONModel::HTTP.get_json(path)
  end

  def location_by_barcode(barcode)
    path = "/locations/barcodes/#{barcode}"
    JSONModel::HTTP.get_json(path)
  end

  def shelve_it(data)
    response = shelve_it_request(shelve_it_uri, data)
    result   = ASUtils.json_parse(response.body) rescue nil

    if response.code =~ /^(4|5)/
      flash[:error]  = response.message
    else
      flash[:success] = "Ok!"
    end
  end

  def shelve_it_request(uri, data)
    JSONModel::HTTP.post_json(URI(uri), data.to_json)
  end

  def shelve_it_uri
    repo_id     = session[:repo_id]
    update_path = 'top_containers/bulk/locations'
    "#{JSONModel::HTTP.backend_url}/repositories/#{repo_id}/#{update_path}"
  end

end