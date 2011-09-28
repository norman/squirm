require 'rake/clean'
require 'rake/testtask'

CLEAN.include "pkg", "spec/coverage", "doc", "*.gem"

task default: :test

task :gem do
  sh "gem build squirm.gemspec"
end

task :test do
  Rake::TestTask.new do |t|
    t.libs << "spec"
    t.test_files = FileList["spec/*_spec.rb"]
    t.verbose = false
  end
end
