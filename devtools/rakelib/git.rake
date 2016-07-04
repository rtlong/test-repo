namespace :git do
  desc 'Ensure Git submodules are initialized and checked out (will not affect local tree if already checked out)'
  task :init_submodules => [:assert_deps] do
    run! 'git', 'submodule', 'init'

    capture!('git', 'submodule', 'status').out.chomp.split("\n").each do |line|
      next unless line.match(/^-/)
      _, path = line.split(/\s+/)

      run! 'git', 'submodule', 'update', '--checkout', '--', path
    end
  end

  desc 'Write git-describe output to a .git-revision file in each project (for injection into Docker containers)'
  task :write_revision_file => [:assert_deps]

  desc 'Install goodguide-git-hooks'
  task :install_hooks => [:assert_deps]

  docker_build_dirs.each do |dir|
    git_revision_file = dir.join('.git-revision')

    task :write_revision_file => [git_revision_file]

    file git_revision_file => [root_path.join('.git')] do |t|
      git_revision = capture!(*%w[git rev-parse HEAD], chdir: dir).out.chomp
      is_clean = system('git', 'diff', '--quiet')
      git_revision << '-dirty' unless is_clean
      File.open(t.name, 'w') { |f| f.puts git_revision }
      announce_action "wrote file #{t.name}: #{git_revision}"
    end
  end

  git_roots.each do |git_root|
    task :install_hooks do
      Rake.chdir git_root do
        run! 'goodguide-git-hooks', 'install', '--noclobber'
      end
    end
  end
end
