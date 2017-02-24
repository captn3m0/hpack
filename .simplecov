SimpleCov.start do
  minimum_coverage 100
  refuse_coverage_drop
  coverage_dir "tmp/coverage/ruby"
  add_filter "/spec/"
end

if ENV['CI'] == true
	require "codeclimate-test-reporter"
	CodeClimate::TestReporter.start
end