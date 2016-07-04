def announce_action(str)
  warn "\e[33m[dev] #{str}\e[0m"
end

def announce_success(str)
  warn "\e[32m[dev] #{str}\e[0m"
end

def announce_failure(str)
  warn "\e[31m[dev] #{str}\e[0m"
end
