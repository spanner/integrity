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
      if @dir
        "(cd #{@dir} && #{restore_env} && #{cmd} 2>&1)"
      else
        "(#{restore_env} && #{cmd} 2>&1)"
      end
    end

    def restore_env
      "RUBYOPT=#{original_rubyopt} PATH=#{original_path}"
    end
    
    def original_path
      ENV['PATH'] && ENV["PATH"].split(":").reject { |path| path.include?("vendor") }.join(":")
    end
    
    def original_rubyopt
      ENV['RUBYOPT'] && ENV["RUBYOPT"].split.reject { |opt| opt.include?("vendor") }.join(" ")
    end
    
  end
end
