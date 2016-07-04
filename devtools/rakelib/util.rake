namespace :util do
  # This exists to help understand the way all the dev tasks fit together. Rake
  # has a `-P` option which is almost enough, but it doesn't fully qualify
  # dependent task names, which is necessary to make sure the graph is correct.
  #
  # n.b. that this skips FileTasks as well as auto_tasks which do not have
  # dependants or depndencies beyond the standard 'bootstrap' task
  #
  # there's a script in devtools/bin to render an SVG from this task --
  # try running devtools/bin/dev-graph
  #
  desc 'Output a graphviz Dot compatible digraph of the tasks defined in `dev`'
  task :task_dependency_graph do
    dependants = Hash.new { |h,k| h[k] = [] }
    tasks_with_deps = Hash.new { |h,k| h[k] = [] }

    Rake.application.tasks.each do |task|
      next if Rake::FileTask === task
      task.prerequisite_tasks.each do |prereq|
        next if Rake::FileTask === prereq
        dependants[prereq.name] << task.name
        tasks_with_deps[task.name] << prereq.name
      end
    end

    puts <<-EOF
digraph dev {
  node [
    style = filled;
    /*fillcolor = black;*/
    /*fontcolor = white;*/
    fontname = "sans-serif";
  ];
  graph [
    fontname = "sans-serif";
    rankdir = LR;
    concentrate = true;
    /* nodesep = 0.5; */
    ranksep = 2;
    /* splines = polyline; */
  ];
  edge [
    fontname = "sans-serif";
    tailport="e";
    headport="w";
    arrowhead=vee;
    penwidth = 1;
  ];
  EOF
    tasks_with_deps.each do |task_name, deps|
      is_auto_task = auto_tasks.include?(task_name)
      next if is_auto_task && dependants[task_name].empty? && deps == ['bootstrap'] && ENV['DEV_GRAPH_NOISY'].to_s.empty?

      task_color = 'white'
      task_color = '#BBBBFF' if is_auto_task
      puts '  %s [style=filled, fillcolor=%s];' % [task_name, task_color].map(&:inspect)
      deps.each do |prereq_name|
        puts '  %s -> %s;' % [task_name, prereq_name].map(&:inspect)
      end
    end
    puts '}'
  end
end
