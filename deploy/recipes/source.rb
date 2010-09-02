include_recipe "deploy::directory"
include_recipe "deploy::scm"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] == 'rails' && !node[:scalarium][:instance][:roles].include?('rails-app')
    Chef::Log.debug("Skipping checking out source code as application #{application} as is a Rails app and this is not a Rails Application Server")
    next 
  end
  
  if deploy[:application_type] == 'php' && !node[:scalarium][:instance][:roles].include?('php-app')
    Chef::Log.debug("Skipping checking out source code as application #{application} as is a PHP app and this is not a PHP Application Server")
    next 
  end
  
  if deploy[:application_type] == 'static' && !node[:scalarium][:instance][:roles].include?('web')
    Chef::Log.debug("Skipping checking out source code as application #{application} as is a static HTML app and this is not a Web Server")
    next 
  end
  
  scalarium_deploy do
    deploy deploy
    application application
  end

  if deploy[:application_type] == 'rails' && node[:scalarium][:instance][:roles].include?('rails-app')
    passenger_web_app do
      application application
      deploy deploy
    end
  end
end

include_recipe "deploy::logrotate"
