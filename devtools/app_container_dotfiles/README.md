When using the example `docker-compose.override.yml` settings, any files you put here will be included in app containers (when running in `DEV_MODE`) as dotfiles.

For example, if you put a file here named `bashrc`, it will be included into the container as `~/.bashrc`
