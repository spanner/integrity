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
      with_env { run_in_dir(command) }
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
    
    # trying to defeat the efforts of both bundler and passenger to keep us in a box
    def with_env(&block)
      env = "GEM_HOME=#{BUILD_GEM_HOME} PATH=#{BUILD_PATH}"
      @logger.debug("restoring env: #{env}")
      runner.setenv(env, &block)
    end

    def runner
      @runner ||= CommandRunner.new(@logger)
    end
    
  end
end
