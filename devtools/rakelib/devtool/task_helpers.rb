def enforce_sanity_check(task_name, msg=task_name)
  sanity_check_task = "#{task_name}_sanity_check"
  task sanity_check_task do
    unless ENV['CONFIRM'].present?
      warn "This is a dangerous operation! You must supply the CONFIRM variable in order to #{msg}!"
      exit 1
    end
  end
  # add to to the top of the list of prerequisites so it fails fast
  Rake::Task[task_name].prerequisites.unshift(sanity_check_task)
end

def primary_task(*args, &block)
  Rake::Task.define_task(*args, &block).tap do |task|
    primary_tasks << task
  end
end

def primary_multitask(*args, &block)
  Rake::MultiTask.define_task(*args, &block).tap do |task|
    primary_tasks << task
  end
end

def primary_tasks
  @primary_tasks ||= Array.new
end

def task_run_exclusively(task)
  Rake.application.top_level_tasks == [task.name]
end

# this collection is used by `dev util:task_dependency_graph`
def auto_tasks
  @auto_tasks ||= []
end

def auto_task(*args, &block)
  task(*args, &block).tap do |t|
    auto_tasks << t.name
  end
end

def build_ci_task(namespace:, test_names:)
  test_services = test_names.map { |name| [name, compose_project_service(namespace, name)] }

  proc do |task|
    test_services.each do |(logical_name, service_name)|
      Rake::Task["#{namespace}:#{logical_name}:start"].invoke

      container_name = container_names_for_compose_service(service_name).first

      run!(*%W[ docker logs -f #{container_name} ])

      if (exit_code = container_exit_status(container_name)) == 0
        announce_success "#{logical_name} finished successfully"
      else
        record_ci_failure "#{namespace}:#{logical_name}"
        announce_failure "#{logical_name} failed (exit=#{exit_code})"
      end

      process_log_dir = "./log/#{logical_name}"
      FileUtils.mkdir_p process_log_dir

      save_container_log_to_file container_name, "#{process_log_dir}/#{logical_name}.out.log"

      run(*%W[ docker cp #{container_name}:/app/log/. #{process_log_dir} ])
    end
  end
end

def ci_failures
  $ci_failures ||= []
end

def record_ci_failure(logical_name)
  ci_failures << logical_name
end
