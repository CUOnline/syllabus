require 'resque/tasks'
require 'rake/testtask'

task :'resque:setup' do
  require './syllabus_worker'
end

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
  t.verbose = false
end
