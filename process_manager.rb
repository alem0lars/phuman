# { Configuration

$config = {
  # The target process name
  process_name: "hon-x86_64",
  # Set to the desired affinity (in the taskset format)
  desired_affinity: "0xFF",
  # Set to a maximum value to limit the number of retries
  max_retries: nil
}

# }


# Manage the process lifecycle
class ProcessManager
  attr_reader :process_name, :desired_affinity, :pid

  def initialize(process_name, desired_affinity)
    @process_name, @desired_affinity = process_name, desired_affinity
  end

  # Get the process pid
  def get_pid
    @pid = `pidof #{process_name}`.delete("\n")
  end

  # Set the process affinity
  def set_affinity
    `taskset -p #{desired_affinity} #{pid}`
  end

  # Get the current affinity for the managed process
  def self.get_affinity
    out = `taskset -p #{pid}`.delete("\n")
    md = out.match /^pid\s#{pid}'s current affinity mask: (.+)$/
    return (md.length > 1) ? md[1] : nil
  end

end


# The program entry point
def main
  pman = ProcessManager.new($config[:process_name], $config[:desired_affinity])
  pid = pman.get_pid
  retries_idx = 0
  begin
    pman.set_affinity(pid)
    retries_idx += 1
  end while(pman.get_affinity == $config[:desired_affinity]) &&
           ($config[:max_retries] == nil || retries_idx < $config[:max_retries])
end

# Start the program
main
