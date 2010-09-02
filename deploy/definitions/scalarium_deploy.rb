define :scalarium_deploy do
  deploy = params[:deploy]
  applcation = params[:application]

  Chef::Log.debug("Preparing source code checkout for application #{application} with type #{deploy[:application_type]}")
  
  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
  end

  # setup deployment & checkout
  deploy deploy[:deploy_to] do
    repository deploy[:scm][:repository]
    user deploy[:user]
    revision deploy[:scm][:revision]
    migrate deploy[:migrate]
    migration_command deploy[:migrate_command]
    environment "RAILS_ENV" => deploy[:rails_env], "RUBYOPT" => "", "RACK_ENV" => deploy[:rails_env]
    symlink_before_migrate deploy[:symlink_before_migrate]
    action deploy[:action]
    restart_command "sleep #{deploy[:sleep_before_restart]} && #{deploy[:restart_command]}"
    case deploy[:scm][:scm_type].to_s
    when 'git'
      scm_provider Chef::Provider::Git
      enable_submodules deploy[:enable_submodules]
      shallow_clone true
    when 'svn'
      scm_provider Chef::Provider::Subversion
      svn_username deploy[:scm][:user]
      svn_password deploy[:scm][:password]
      svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
      svn_info_arguments "--no-auth-cache --non-interactive --trust-server-cert"
    else
      raise "unsupported SCM type #{deploy[:scm][:scm_type].inspect}"
    end

    before_migrate do
      if File.exists?("#{release_path}/Gemfile")
        Chef::Log.info("Gemfile detected. Running bundle install.")
        sudo("cd #{release_path} && bundle install --system --without=test")
      end
      run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
    end
  end


end
