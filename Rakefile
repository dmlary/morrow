
# I'm going to be honest, this is a big pile of shit to just get the damn thing
# to build into public without repeatedly adding the <script> tags.  It looks
# like they take whatever is in public/index.html, then inject the <script>s,
# but when it's something they've generated, we just get dozens of tags.  This
# is a shit work-around until someone with more experience has a better
# solution.
task :build do
  rm 'public/index.html' if File.exists?('public/index.html')
  sh 'npm run build'
  sh 'rsync -avp dist/ public/'
  rm_rf 'dist'
end

task :default => :build

task :test do
  sh 'bundle exec rspec'
end

task :lint do
  sh 'npm run lint'
end

task 'start-dev' => :build do
  sh 'bundle exec foreman start --root %s --procfile config/Procfile-dev' %
      [ File.dirname(__FILE__) ]
end

task :pry do
  sh 'bundle exec pry-remote -s localhost -p 4321'
end
