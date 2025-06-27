class ShelveItController < ApplicationController
  set_access_control  'update_container_record' => %i[index update],
                      'shelve_it_assignment' => %i[index update],
                      'view_repository' => %i[index update]

  def index
    @shelving_assignments = lookup_shelving_assignments
  end

  def update
    container_barcode = params[:container_barcode]
    location_barcode  = params[:location_barcode]
    persist_location  = params[:persist_location]

    begin
      container = container_by_barcode(container_barcode)
    rescue RecordNotFound
      flash[:error] = "Container barcode not found: #{container_barcode}"
    end

    begin
      location = location_by_barcode(location_barcode) if container
    rescue RecordNotFound
      flash[:error] = "Location barcode not found: #{location_barcode}"
    end

    shelve_it(container['uri'] => location['uri']) if container && location

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
    JSONModel::HTTP.get_json(path)
  end

  def location_by_barcode(barcode)
    path = "/locations/by_barcode/#{barcode}"
    JSONModel::HTTP.get_json(path)
  end

  def lookup_shelving_assignments(limit: 10)
    repo_id = session[:repo_id]
    path    = "/repositories/#{repo_id}/shelve_it/assignments"
    JSONModel::HTTP.get_json(path, { limit: limit })
  end

  def shelve_it(data)
    response = shelve_it_request(shelve_it_uri, data)
    if response.code =~ /^(4|5)/
      flash[:error]  = response.message
    else
      flash[:success] = 'Ok!'
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
