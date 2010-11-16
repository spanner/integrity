module Integrity
  class CommandRunner
    class Error < StandardError; end

    Result = Struct.new(:success, :output)

    def initialize(logger)
      @logger = logger
    end

    def cd(dir)
      @dir = dir
      yield self
    ensure
      @dir = nil
    end
    
    def setenv(env)
      @env = env
      yield self
    end

    def run(command)
      cmd = normalize(command)

      @logger.debug(cmd)

      output = ""
      IO.popen(cmd, "r") { |io| output = io.read }

      Result.new($?.success?, output.chomp)
    end

    def run!(command)
      result = run(command)

      unless result.success
        @logger.error(output.inspect)
        raise Error, "Failed to run '#{command}'"
      end

      result
    end

    def normalize(cmd)
      cmd = "#{@env} && #{cmd}" if @env
      cmd = "cd #{@dir} && #{cmd}" if @dir
      "(#{cmd} 2>&1)"
    end

  end  
end
