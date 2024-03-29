class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/locations/by_barcode/:barcode')
    .description('Get a Location by barcode')
    .params(['barcode', String],
            ['resolve', :resolve])
    .permissions([])
    .returns([200, '(:location)'], [404, "Not found"]) \
  do
    location = location_barcode(params[:barcode])
    raise NotFoundException.new("Location not found") unless location

    json_response(resolve_references(Location.to_jsonmodel(location.id), params[:resolve]))
  end

  Endpoint.get('/repositories/by_repo_code/:repo_code')
    .description('Get a repository by repo_code')
    .params(['repo_code', String],
            ['resolve', :resolve])
    .permissions([])
    .returns([200, '(:repository)'], [404, "Not found"]) \
  do
    repository = repository_repo_code(params[:repo_code])
    raise NotFoundException.new("Repository not found") unless repository

    json_response(resolve_references(Repository.to_jsonmodel(repository.id), params[:resolve]))
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
        default: 10,
      ])
    .permissions([:view_repository])
    .returns([200, '(:array)']) \
  do
    json_response(shelve_it_assignments(limit: params[:limit]))
  end

  Endpoint.get('/repositories/:repo_id/top_containers/by_barcode/:barcode')
    .description('Get a top container by barcode')
    .params(['barcode', String],
            ['repo_id', :repo_id],
            ['resolve', :resolve])
    .permissions([:view_repository])
    .returns([200, '(:top_container)'], [404, "Not found"]) \
  do
    container = TopContainer.for_barcode(params[:barcode])
    raise NotFoundException.new("Container not found") unless container

    json_response(resolve_references(TopContainer.to_jsonmodel(container.id), params[:resolve]))
  end

  private

  def location_barcode(barcode)
    Location[barcode: barcode]
  end

  def repository_repo_code(repo_code)
    Repository[repo_code: repo_code]
  end

  def shelve_it_assignments(limit: 10)
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
          Sequel.as(:top_container__id, :top_container_id),
          Sequel.as(:top_container__last_modified_by, :updated_by),
          Sequel.as(:top_container_housed_at_rlshp__status, :status),
          Sequel.as(:top_container_housed_at_rlshp__user_mtime, :updated_at),
        )
        .exclude(top_container__barcode: nil)
        .all
    end
    result
  end

end
