class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/locations/barcodes/:barcode')
    .description('Get a Location by barcode')
    .params(['barcode', String],
            ['resolve', :resolve])
    .permissions([])
    .returns([200, '(:location)']) \
  do
    # location = Location.for_barcode(params[:barcode])
    location = location_barcode(params[:barcode])
    id       = location.nil? ? -1 : location.id
    json     = Location.to_jsonmodel(id)
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/shelve_it/assignments')
    .description('Get recent container location assignments')
    .params(
      ['repo_id', :repo_id],
      [
        'limit',
        Integer,
        'Limit number of records returned',
        optional: true,
        default: 3,
      ])
    .permissions([:view_repository])
    .returns([200, '(:array)']) \
  do
    json_response(shelve_it_assignments(limit: params[:limit]))
  end

  Endpoint.get('/repositories/:repo_id/top_containers/barcodes/:barcode')
    .description('Get a top container by barcode')
    .params(['barcode', String],
            ['repo_id', :repo_id],
            ['resolve', :resolve])
    .permissions([:view_repository])
    .returns([200, '(:top_container)']) \
  do
    container = TopContainer.for_barcode(params[:barcode])
    id        = container.nil? ? -1 : container.id
    json      = TopContainer.to_jsonmodel(id)
    json_response(resolve_references(json, params[:resolve]))
  end

  private

  # TODO: add to model
  def location_barcode(barcode)
    Location[barcode: barcode]
  end

  def shelve_it_assignments(limit: 3)
    result = []
    DB.open do |db|
      result += db[:location]
        .join(
          :top_container_housed_at_rlshp,
          :top_container_housed_at_rlshp__location_id => :location__id
        )
        .join(
          :top_container,
          :top_container__id => :top_container_housed_at_rlshp__top_container_id
        )
        .order(Sequel.desc(:top_container_housed_at_rlshp__user_mtime))
        .limit(limit)
        .select(
          Sequel.as(:location__barcode, :location_barcode),
          Sequel.as(:location__id, :location_id),
          Sequel.as(:location__title, :location_title),
          Sequel.as(:top_container__barcode, :top_container_barcode),
          Sequel.as(:top_container_housed_at_rlshp__status, :status),
          Sequel.as(:top_container_housed_at_rlshp__user_mtime, :updated_at),
          Sequel.as(:top_container__id, :top_container_id),
        )
        .all
    end
    result
  end

end