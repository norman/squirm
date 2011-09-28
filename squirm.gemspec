require File.expand_path("../lib/squirm/version", __FILE__)

Gem::Specification.new do |s|
  s.name          = "squirm"
  s.version       = Squirm::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Norman Clarke"]
  s.email         = ["norman@njclarke.com"]
  s.homepage      = "http://github.com/norman/squirm"
  s.summary       = %q{"An anti-ORM for database-loving programmers"}
  s.description   = %q{"Squirm is an anti-ORM for database-loving programmers"}
  s.bindir        = "bin"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 1.9"

  s.add_development_dependency "minitest"
  s.add_runtime_dependency "pg"

end
