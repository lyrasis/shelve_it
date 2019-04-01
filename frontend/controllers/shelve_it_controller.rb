class ShelveItController < ApplicationController

  set_access_control  "update_container_record" => [:index, :update],
                      "update_location_record"  => [:index, :update],
                      "view_repository"         => [:index, :update]

  def index
    # TODO (gather data for dash)
    @shelving_assignments = lookup_shelving_assignments
  end

  def update
    container_barcode = params[:container_barcode]
    location_barcode  = params[:location_barcode]
    persist_location  = params[:persist_location]

    container = container_by_barcode(container_barcode)
    location  = location_by_barcode(location_barcode)

    if container && location
      shelve_it(container['uri'] => location['uri'])
    else
      bad = [container_barcode.strip, location_barcode.strip].compact.join(',')
      flash[:error] = "Error, check barcodes exist! #{bad}"
    end

    redirect_to controller: :shelve_it,
      action: :index,
      location_barcode: location_barcode,
      persist_location: persist_location
  end

  def container_uri(id)
    "#{AppConfig[:frontend_proxy_prefix]}/top_containers/#{id}".squeeze('/')
  end
  helper_method :container_uri

  def location_uri(id)
    "#{AppConfig[:frontend_proxy_prefix]}/locations/#{id}".squeeze('/')
  end
  helper_method :location_uri

  private

  def container_by_barcode(barcode)
    repo_id = session[:repo_id]
    path    = "/repositories/#{repo_id}/top_containers/by_barcode/#{barcode}"
    JSONModel::HTTP.get_json(URI.encode(path))
  end

  def location_by_barcode(barcode)
    path = "/locations/by_barcode/#{barcode}"
    JSONModel::HTTP.get_json(URI.encode(path))
  end

  def lookup_shelving_assignments(limit: 10)
    repo_id = session[:repo_id]
    path    = "/repositories/#{repo_id}/shelve_it/assignments"
    JSONModel::HTTP.get_json(path, { limit: limit })
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