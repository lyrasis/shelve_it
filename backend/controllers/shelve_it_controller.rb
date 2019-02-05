class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/locations/barcodes/:barcode')
    .description("Get a Location by barcode")
    .params(["barcode", String],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:location)"]) \
  do
    # location = Location.for_barcode(params[:barcode])
    location = location_barcode(params[:barcode])
    id       = location.nil? ? -1 : location.id
    json     = Location.to_jsonmodel(id)
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/top_containers/barcodes/:barcode')
    .description("Get a top container by barcode")
    .params(["barcode", String],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:top_container)"]) \
  do
    container = TopContainer.for_barcode(params[:barcode])
    id        = container.nil? ? -1 : container.id
    json      = TopContainer.to_jsonmodel(id)
    json_response(resolve_references(json, params[:resolve]))
  end

  private

  # TODO: add to model
  def location_barcode(barcode)
    Location[:barcode => barcode]
  end

end