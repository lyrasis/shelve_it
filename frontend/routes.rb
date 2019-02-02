ArchivesSpace::Application.routes.draw do
  scope AppConfig[:frontend_proxy_prefix] do
    match('/plugins/shelve_it/update' => 'shelve_it#update', :via => [:post])
  end
end