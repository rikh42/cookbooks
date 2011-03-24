
include_recipe "deploy"

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping rails::configure for application #{application} as it is not an Rails app")
    next
  end

  scalarium_rails do
    deploy_data deploy
    app application
  end

end