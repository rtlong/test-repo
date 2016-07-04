require 'devtool/helpers'
require 'devtool/ui'

namespace :ci do
  desc 'Full CI run as performed by Jenkins'
  primary_task :run => %w[
    report_results_at_exit
    ensure_CI_variable_is_set
    ensure_COMPOSE_FILE_variable_is_set
    update_images
  ]

  task :report_results_at_exit do
    at_exit do
      if ci_failures.any?
        ci_failures.each do |logical_name|
          announce_failure "FAIL: #{logical_name} failed"
        end
        Kernel.exit false
      else
        if $!.nil? || $!.is_a?(SystemExit) && $!.success?
          announce_success "BUILD SUCCESSFUL"
        else
          announce_failure "FAIL: something failed"
        end
      end
    end
  end

  task :ensure_CI_variable_is_set do
    ENV['CI'].presence or ENV['CI'] = 'true'
  end

  # force-override the COMPOSE_FILE variable to disable the possible local overrides file, for CI
  task :ensure_COMPOSE_FILE_variable_is_set do
    ENV['COMPOSE_FILE'] = 'docker-compose.yml'
  end

  task :setup_environment_variables => %w[ ensure_CI_variable_is_set ensure_COMPOSE_FILE_variable_is_set ]
end
