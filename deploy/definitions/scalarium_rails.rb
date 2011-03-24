define :scalarium_rails do
  deploy = params[:deploy_data]
  application = params[:app]

  include_recipe "#{deploy[:stack][:service]}::service" if deploy[:stack][:service]

  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
    command "touch tmp/restart.txt"
    action :nothing
  end

  ruby_block 'Determine database adapter' do
    inner_deploy = deploy
    inner_application = application
    block do
      inner_deploy[:database][:adapter] = if File.exists?("#{inner_deploy[:deploy_to]}/current/config/application.rb")
        Chef::Log.info("Looks like #{inner_application} is a Rails 3 application")
        'mysql2'
      else
        Chef::Log.info("No config/application.rb found, assuming #{inner_application} is a Rails 2 application")
        'mysql'
      end
    end
  end

  # write out database.yml
  template "#{deploy[:deploy_to]}/shared/config/database.yml" do
    cookbook "rails"
    source "database.yml.erb"
    mode "0660"
    owner deploy[:user]
    group deploy[:group]
    variables(:database => deploy[:database], :environment => deploy[:rails_env])
    if deploy[:stack][:needs_reload]
      notifies :run, resources(:execute => "restart Rails app #{application}")
    end
  end

  # write out memcached.yml
  template "#{deploy[:deploy_to]}/shared/config/memcached.yml" do
    cookbook "rails"
    source "memcached.yml.erb"
    mode "0660"
    owner deploy[:user]
    group deploy[:group]
    variables(:memcached => deploy[:memcached], :environment => deploy[:rails_env])
    if deploy[:stack][:needs_reload]
      notifies :run, resources(:execute => "restart Rails app #{application}")
    end
  end

  execute "symlinking subdir mount if necessary" do
    command "rm -f /var/www/#{deploy[:mounted_at]}; ln -s #{deploy[:deploy_to]}/current/public /var/www/#{deploy[:mounted_at]}"
    action :run
    only_if do
      deploy[:mounted_at] && !File.symlink?("/var/www/#{deploy[:mounted_at]}")
    end
  end

  passenger_web_app do
    application application
    deploy deploy
  end
end 
