set :application, "integrity"
set :scm, :git
set :repository, "git@github.com:spanner/#{application}.git"
set :ssh_options, { :forward_agent => true }

set :user, 'spanner'
set :group, 'spanner'
set :branch, 'master'

role :web, "moriarty.spanner.org"
role :app, "moriarty.spanner.org"
set :rails_env, 'production'

set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
default_run_options[:pty] = true

after "deploy:setup" do
  sudo "mkdir -p #{deploy_to}/logs" 
  sudo "mkdir -p #{shared_path}/shared" 
  sudo "chown -R #{user}:#{group} #{deploy_to}"
end

after "deploy:update" do
  run "ln -s #{shared_path}/shared #{current_release}/shared" 
  run "ln -s #{shared_path}/builds #{current_release}/builds" 
  run "ln -s #{shared_path}/data/integrity.db #{current_release}/integrity.db" 
  run "ln -s #{shared_path}/init.rb #{current_release}/init.rb" 
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
  desc "remove entirely the remote repository cache"
  task :clear_cached_copy do
    run "rm -rf #{shared_path}/cached-copy"
  end
end

namespace :jobs do
  desc "Start delayed_job worker" 
  task :start, :roles => :app do
    run "cd #{current_path}; script/job_runner start #{rails_env}" 
  end

  desc "Stop delayed_job worker" 
  task :stop, :roles => :app do
    run "cd #{current_path}; script/job_runner stop #{rails_env}" 
  end

  desc "Restart delayed_job worker" 
  task :restart, :roles => :app do
    run "cd #{current_path}; script/job_runner restart #{rails_env}" 
  end
end

after "deploy:start", "jobs:start" 
after "deploy:stop", "jobs:stop" 
after "deploy:restart", "jobs:restart" 
