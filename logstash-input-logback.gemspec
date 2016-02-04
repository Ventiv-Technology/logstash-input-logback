Gem::Specification.new do |s|

  s.name            = 'logstash-input-logback'
  s.version         = '0.2.0'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "Read events over a TCP socket from a Logback SocketAppender"
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["John Crygier"]
  s.email           = 'john.crygier@ventivtech.com'
  s.homepage        = "http://www.ventivtech.com/"
  s.require_paths = ["lib"]

  # Files
  #s.files = `git ls-files`.split($\)+::Dir.glob('vendor/*')
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Jar dependencies
  s.requirements << "jar 'ch.qos.logback:logback-classic', '1.1.3'"
  s.requirements << "jar 'ch.qos.logback:logback-core', '1.1.3'"
  s.requirements << "jar 'org.slf4j:slf4j-api', '1.7.14'"

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core', '>= 2.0.0', '< 3.0.0'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'jar-dependencies'
  s.add_development_dependency 'logstash-devutils'
end
