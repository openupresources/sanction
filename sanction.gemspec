$:.push File.expand_path("../lib", __FILE__)

require 'sanction/version'

Gem::Specification.new do |s|
  s.name      = "sanction"
  s.version   = Sanction::VERSION.dup
  s.platform  = Gem::Platform::RUBY

  s.summary   = "A configurable token based authorization gem"
  s.email     = "peterleonhardt@gmail.com"
  s.description = "A configurable token based authorization gem"
  s.authors   = ["Peter Leonhardt", "Matthew Vermaak"]

  s.required_ruby_version = '>= 2.1.0'

  s.require_paths = ["lib"]
  s.add_dependency("railties", ">= 5.0")
end
