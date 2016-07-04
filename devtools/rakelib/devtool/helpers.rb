require 'pathname'
require 'devtool/ui'
require 'devtool/core_ext'
require 'devtool/shellout'

def root_path
  require 'pathname'
  @root_path ||= Pathname.new(File.expand_path('../../', Rake.application.rakefile))
end

def container_names_for_compose_service(service_name)
  capture!('docker', 'ps', '-a',
    '--filter', "label=com.docker.compose.project=#{compose_project_name}",
    '--filter', "label=com.docker.compose.service=#{service_name}",
    '--format', '{{ .Names }}'
  ).out.chomp.split(/\s+/)
end

def docker_compose_config
  require 'yaml'
  @docker_compose_config ||= YAML.load(load_docker_compose_config)
end

def load_docker_compose_config
  require 'digest'
  files = FileList.new('docker-compose*')
  digest = Digest::SHA256.new
  if (explicit_compose_file = ENV['COMPOSE_FILE'].presence)
    files.add explicit_compose_file
    digest << "COMPOSE_FILE=#{explicit_compose_file}"
  end
  digest << compose_project_name
  files.each do |f|
    digest << File.read(f)
  end
  cache_file = root_path.join("tmp/docker-compose.config.#{digest.hexdigest}.yml")

  if cache_file.exist?
    return cache_file.read
  end

  cache_file.dirname.mkdir

  yaml = run_docker_compose_config
  cache_file.open('w') { |f| f.puts yaml }
  yaml
end

def run_docker_compose_config
  capture!('docker-compose', 'config').out
end

def runnable_services
  docker_compose_config['services'].reduce([]) do |runnable, (service_name, service)|
    if service['command'] != 'true' && !service_name.match(/-image$/)
      runnable << service_name
    end
    runnable
  end
end

def buildable_services
  docker_compose_config['services'].reduce([]) do |buildable, (service_name, service)|
    if service['build']
      buildable << service_name
    end
    buildable
  end
end

def pullable_services
  docker_compose_config['services'].reduce([]) do |pullable, (service_name, service)|
    if !service['build'] && (image = service['image']).present? && !image.match(/^#{compose_project_name}_/)
      pullable << service_name
    end
    pullable
  end
end

def compose_project_name
  ENV['COMPOSE_PROJECT_NAME'].presence
end

def docker_build_dirs
  FileList.new('**/Dockerfile').resolve.map { |dockerfile|
    Pathname.new(dockerfile).dirname
  }
end

def git_roots
  submodule_paths = capture!('git', 'submodule', 'foreach', '--quiet', 'echo $path').out.split("\n").map(&:presence).compact
  [root_path] + submodule_paths
end

# returns the proper name of the docker-compose service identified by the named
# project and service. Useful for task-load-time early assertion that tasks are
# in-sync with docker-compose.
def compose_project_service(project, service_name)
  matches = runnable_services.grep(/^#{project}-#{service_name}$/)
  if matches.one?
    return matches.first
  elsif matches.empty?
    raise "no docker-compose service match for #{project} and #{service_name}"
  else
    raise "ambiguous docker-compose service match for #{project} and #{service_name}: #{matches.inspect}"
  end
end
