module Integrity
  class Checkout
    def initialize(repo, commit, directory, logger)
      @repo      = repo
      @commit    = commit
      @directory = directory
      @logger    = logger
    end

    def run
      runner.run! "git clone #{@repo.uri} #{@directory}"

      in_dir do |c|
        c.run! "git fetch origin"
        c.run! "git checkout origin/#{@repo.branch}"
        c.run! "git reset --hard #{sha1}"
      end
    end

    def metadata
      format = "---%nidentifier: %H%nauthor: %an " \
        "<%ae>%nmessage: >-%n  %s%ncommitted_at: %ci%n"
      result = run_in_dir!("git show -s --pretty=format:\"#{format}\" #{sha1}")
      dump   = YAML.load(result.output)

      dump.update("committed_at" => Time.parse(dump["committed_at"]))
    end

    def sha1
      @sha1 ||= @commit == "HEAD" ? head : @commit
    end

    def head
      runner.run!("git ls-remote --heads #{@repo.uri} #{@repo.branch}").
        output.split.first
    end

    def run_with_env(command)
      with_env {
        run_in_dir(command)
      }
    end

    def run_in_dir(command)
      in_dir { |r| r.run(command) }
    end

    def run_in_dir!(command)
      in_dir { |r| r.run!(command) }
    end

    def in_dir(&block)
      runner.cd(@directory, &block)
    end
    
    def with_env(&block)
      env = "RUBYOPT = #{original_rubyopt} PATH=#{original_path}"
      @logger.debug("restoring env: #{env}")
      runner.setenv(env, &block)
    end

    def runner
      @runner ||= CommandRunner.new(@logger)
    end
    
  private

    def original_path
      ENV['PATH'] && ENV["PATH"].split(":").reject { |path| path.include?("vendor") }.join(":")
    end
  
    def original_rubyopt
      ENV['RUBYOPT'] && ENV["RUBYOPT"].split.reject { |opt| opt.include?("vendor") }.join(" ")
    end

  end
end
