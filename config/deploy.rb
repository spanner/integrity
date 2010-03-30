set :application, "integrity"
set :scm, :git
set :repository, "git@github.com:spanner/#{application}.git"
set :ssh_options, { :forward_agent => true }

set :user, 'spanner'
set :group, 'spanner'
set :branch, 'master'

role :web, "moriarty.spanner.org"
role :app, "moriarty.spanner.org"

set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
default_run_options[:pty] = true

after "deploy:setup" do
  sudo "mkdir -p #{deploy_to}/logs" 
  sudo "mkdir -p #{shared_path}/shared" 
  sudo "chown -R #{user}:#{group} #{shared_path}"
  sudo "chown #{user}:#{group} /var/www/#{application}/releases"
end

after 'deploy:update_code', 'bundler:install'

after "deploy:update" do
  run "ln -s #{shared_path}/shared #{current_release}/shared" 
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
  task :stop, :roles => :app do
    # There is no stop.
  end
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
  desc "remove entirely the remote repository cache"
  task :clear_cached_copy do
    run "rm -rf #{shared_path}/cached-copy"
  end
end

namespace :bundler do
  desc "Install the bundler gem"
  task :install_gem do
    sudo("gem install bundler --source=http://gemcutter.org")
  end

  desc "Install and lock the bundle"
  task :install do
    run("cd #{current_release} && bundle install && bundle lock")
  end
end

