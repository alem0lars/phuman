#!/usr/bin/env ruby


# { Configuration

$config = {
  # The target process name
  process_name: "hon-x86_64",
  # Set to the desired affinity (in the taskset format; e.g. 0xFF)
  desired_affinity: "0xFF",
  # Set to a maximum value to limit the number of retries
  max_retries: nil,
  # The default delay
  delay: 1
}

# }


# Manage the process lifecycle
class ProcessManager
  attr_reader :process_name, :desired_affinity, :pid, :delay

  def initialize(process_name, desired_affinity, delay)
    @process_name = process_name
    @desired_affinity = desired_affinity
    @delay = delay

    initialize_pid
  end

  # Set the process affinity
  def set_affinity
    unless @pid.nil?
      `taskset -p #{desired_affinity} #{pid}`
      return $?.success?
    else
      return false
    end
  end

  # Get the current affinity for the managed process
  def get_affinity
    unless @pid.nil?
      out = `taskset -p #{pid}`.delete("\n")
      md = out.match(/^pid\s#{pid}'s current affinity mask: (.+)$/)
      return (md.length > 1) ? md[1] : nil
    else
      return nil
    end
  end

  # Wait for the delay
  def wait_delay
    sleep(delay)
  end

  def fix_desired_affinity(opts = {})
    # { Parse the options
    raise "Argument error" unless opts.is_a?(Hash)
    opts = {
      without_0x: true,
      downcase: true
    }.merge(opts)
    # }

    result = desired_affinity.dup

    result.gsub!(/^0x/, "") if opts[:without_0x]
    result.downcase! if opts[:downcase]

    return result
  end

  # Fetch the pid from the process name and set the corresponding property
  def setup_pid
    initialize_pid
  end

  protected

    def initialize_pid
      @pid = `pidof #{process_name}`.delete("\n")
      @pid = @pid.empty? ? nil : @pid
    end

end


# The program entry point
def main

  puts ">>> Starting"

  pman = ProcessManager.new(
      $config[:process_name],
      $config[:desired_affinity],
      $config[:delay])

  retries_idx = 0

  while (pman.get_affinity != pman.fix_desired_affinity(without_0x: true, downcase: true)) &&
        ($config[:max_retries] == nil || retries_idx < $config[:max_retries])
    pman.set_affinity
    pman.setup_pid
    retries_idx += 1
    pman.wait_delay
    puts ">> Waiting for #{pman.process_name}"
  end
  puts ">> Process affinity: #{pman.get_affinity}"

  puts "<<< Finishing"

end


# Start the program
main
