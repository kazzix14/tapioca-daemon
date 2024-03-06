# frozen_string_literal: true

require_relative "lib/tapioca/daemon/version"

Gem::Specification.new do |spec|
  spec.name = "tapioca-daemon"
  spec.version = Tapioca::Daemon::VERSION
  spec.authors = ["Kazuma Murata"]
  spec.email = ["kazzix14@gmail.com"]

  spec.summary = "tapioca daemon"
  spec.description = "tapioca daemon"
  spec.homepage = "https://github.com/kazzix14/tapioca-daemon"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kazzix14/tapioca-daemon"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.executables << 'tapioca-daemon'
  spec.bindir = "exe"
  #spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "tapioca"
  spec.add_dependency "listen"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
