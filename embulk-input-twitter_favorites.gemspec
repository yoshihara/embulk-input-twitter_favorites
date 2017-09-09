
Gem::Specification.new do |spec|
  spec.name          = "embulk-input-twitter_favorites"
  spec.version       = "0.1.0"
  spec.authors       = ["yoshihara"]
  spec.summary       = "Twitter Favorites input plugin for Embulk"
  spec.description   = "Loads records from Twitter Favorites."
  spec.email         = ["yoshihara@users.noreply.github.com"]
  spec.licenses      = ["MIT"]
  # TODO set this: spec.homepage      = "https://github.com/yoshihara/embulk-input-twitter_favorites"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'twitter'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'embulk', ['>= 0.8.32']
  spec.add_development_dependency 'bundler', ['>= 1.10.6']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
