# This file automatically defines a couple tasks for any 'app' service defined
# in the docker-compose file. mostly these are meant to be referenced by other,
# higher-level tasks in the dev tool, but there's no reason not to use them
# manually as well!

test_services_pattern = /(test|rspec|cucumber|karma)$/
project_services_pattern = /^#{Regexp.union(PROJECTS)}/

test_services = Hash.new { |h,k| h[k] = [] }

runnable_services.grep(project_services_pattern).each do |docker_compose_service|
  project_name, service_name = docker_compose_service.split('-', 2).map { |n| n.gsub(/\W+/, '_') }

  namespace project_name do
    namespace service_name do
      desc "docker-compose up -d #{docker_compose_service}"
      auto_task :start => %w[ rake:bootstrap ] do
        run!(*%W[ docker-compose up -d #{docker_compose_service} ])
      end

      desc "docker-compose up #{docker_compose_service}"
      auto_task :run => %w[ rake:bootstrap ] do
        run!(*%W[ docker-compose up #{docker_compose_service} ])
      end

      desc "Run a bash shell in the environment of Purview #{docker_compose_service}"
      auto_task :shell => %w[ rake:bootstrap ] do
        run!(*%W[ docker-compose run --rm #{docker_compose_service} bash ])
      end
    end

    if test_services_pattern =~ service_name
      test_services[project_name] << docker_compose_service
    end
  end
end

test_services.each_pair do |project_name, docker_compose_service_names|
  namespace project_name do
    namespace :test do
      desc "Run all #{project_name} in foreground"
      auto_task :run_all => %w[ rake:bootstrap ] do
        run!(*%W[ docker-compose up ] + docker_compose_service_names)
      end
    end
  end
end

buildable_services.grep(project_services_pattern).each do |docker_compose_service|
  project_name, service_name = docker_compose_service.split('-', 2).map { |n| n.gsub(/\W+/, '_') }

  namespace project_name do
    namespace service_name do
      desc "docker-compose build --pull #{docker_compose_service}"
      auto_task :build => %w[ rake:bootstrap ] do
        run!(*%W[ docker-compose build --pull #{docker_compose_service} ])
      end
    end

    desc "Builds all #{project_name}-specific docker images"
    auto_task :build => %W[ #{service_name}:build ]
  end
end
