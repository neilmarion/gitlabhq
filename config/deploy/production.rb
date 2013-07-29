set :user, "deployer"
set :home, "git"
set :branch, "capistrano"
set :application, "gitlab"
set :deploy_to, "/home/#{home}/#{application}"

set :rails_env, "production"

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "restarting nginx"
    task command, roles: :app, except: {no_release: true} do
      sudo "service nginx restart" 
    end 
  end 

  task :setup_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml.mysql"), "#{shared_path}/config/database.yml"
    put File.read("config/gitlab.yml.example"), "#{shared_path}/config/gitlab.yml"
    puts "Now edit the config files in #{shared_path}."
  end 
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/gitlab.yml #{release_path}/config/gitlab.yml"
  end 
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/#{branch}"
      puts "Run `git push` to sync changes."
      exit
    end 
  end 
  before "deploy", "deploy:check_revision"
end
