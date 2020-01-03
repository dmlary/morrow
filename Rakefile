task :build do
  sh 'npm run build'
  sh 'rsync -avp dist/ public/'
  rm_rf 'dist'
end

task :default => :build

task :test do
  sh 'bundle exec rspec'
end

task 'start-dev' => :build do
  sh 'bundle exec foreman start --root %s --procfile config/Procfile-dev' %
      [ File.dirname(__FILE__) ]
end

task :pry do
  sh 'bundle exec pry-remote -s localhost -p 4321'
end

task :test do
  sh 'bundle exec rspec'
end


