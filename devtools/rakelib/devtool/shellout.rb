require 'shellwords'
require 'devtool/ui'

# given all the arguments to Kernel.spawn, form a (nearly) bourne-shell like string to indicate what's being run
def pretty_print_spawn_args(*args)
  env_vars = []
  precommands = []

  if Hash === args.first
    env = args.shift
    env_vars = env.each_pair.map { |key, val|
      "#{Shellwords.escape(key)}=#{Shellwords.escape(val)}"
    }
  end

  if Hash === args.last
    options = args.pop
    precommands << Shellwords.join(['cd', options[:chdir]]) if options[:chdir]
  end

  # command is what's left
  command = args

  # if [commandname,argv0] was given, just ignore argv0 so we can print a shell compatible string
  command[0] = command[0].first if Array === command[0]

  # if only one component, assume already a shell-bound command string, and don't escape it again
  command_string = command.one? ? command.first : Shellwords.join(command)

  [*precommands, [*env_vars, command_string].join(' ')].join(' && ')
end

# like Kernel.system, but with automatic log output of what's being run
def run(*args)
  announce_action pretty_print_spawn_args(*args)
  system(*args)
end

# version of #run with explicit raise when something fails
def run!(*args)
  run(*args) or
    raise "COMMAND FAILED (exit=#{$?.exitstatus}): #{pretty_print_spawn_args(*args)}"
end

class ProcessOutput < Struct.new(:out, :status)
  def success?
    status.success?
  end
end

# same semantics as #run but you get the stdout and the success as the return
def capture(*args)
  require 'open3'
  ProcessOutput.new(*Open3.capture2(*args))
end

# same semantics as #capture but with an explicit raise when something fails
def capture!(*args)
  response = capture(*args)
  response.success? or raise "COMMAND FAILED (exit=#{response.status.exitstatus}): #{pretty_print_spawn_args(*args)}"
  response
end
