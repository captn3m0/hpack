require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec') do |t|
  t.exclude_pattern = 'spec/hpack_test_case_spec.rb'
end

RSpec::Core::RakeTask.new('hpack_test_case') do |t|
  t.pattern = 'spec/hpack_test_case_spec.rb'
end

# If you want to make this the default task
task :default => :spec