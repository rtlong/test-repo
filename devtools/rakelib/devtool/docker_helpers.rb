require 'devtool/ui'
require 'devtool/shellout'

# use a shell to redirect output, instead of ever bringing this outout into ruby at all
def save_container_log_to_file(container_id, filename, follow: false, timestamps: true)
  docker_args = []
  docker_args << '-f' if follow
  docker_args << '-t' if timestamps

  command = [
    'docker', 'logs', *docker_args, container_id.shellescape,
     '>', filename.shellescape, '2>&1'
  ]
  run! command.join(' ')
end

def abort_if_container_failed(container_id, message=nil)
  message ||= "Container #{container_id} failed"
  exitstatus = container_exit_status(container_id)
  exitstatus == 0 or abort message << " (exit=#{exitstatus})"
end

def container_exit_status(container_id)
  capture!('docker', 'wait', container_id).out.to_i
end
