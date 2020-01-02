task :dev do
  sh 'bundle exec foreman start'
end

task :pry do
  sh 'bundle exec pry-remote -s localhost -p 4321'
end

task :test do
  sh 'bundle exec rspec'
end
