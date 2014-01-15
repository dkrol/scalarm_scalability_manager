ScalarmScalabilityManager::Application.routes.draw do
  get "monitoring/index"
  get "monitoring/show"
  root 'platform#index'

  get 'platform' => 'platform#index'
  get 'platform/index'
  post 'platform/synchronize'
  post 'platform/addWorkerNode'
  post 'platform/removeWorkerNode'
  post 'platform/deployManager'
  post 'platform/deploy_simulation_manager'

  delete 'scalarm_managers/:id' => 'scalarm_managers#destroy'

  get 'scalarm_managers/worker_nodes'
  get 'scalarm_managers/managers'
  get 'scalarm_managers/manager_labels'
  get 'scalarm_managers/simulation_managers'

  get 'monitoring' => 'monitoring#index'
  get 'monitoring/index'
  post 'monitoring/show'
  get 'monitoring/show'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
