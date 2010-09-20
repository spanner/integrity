require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :required => true, :unique => true
    property :permalink,  String
    property :uri,        URI,      :required => true, :length => 255
    property :branch,     String,   :required => true, :default => "master"
    property :command,    String,   :required => true, :length => 255, :default => "rake"
    property :public,     Boolean,  :default  => true

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :notifiers

    before :save, :set_permalink

    before :destroy do
      builds.destroy!
    end

    def repo
      @repo ||= Repository.new(uri, branch)
    end

    def build_head
      build(Commit.new(:identifier => "HEAD"))
    end

    def build(commit)
      _build = builds.create(:commit => {
        :identifier   => commit.identifier,
        :author       => commit.author,
        :message      => commit.message,
        :committed_at => commit.committed_at
      })
      _build.run
      _build
    end

    def fork(new_branch)
      forked = Project.create(
        :name    => "#{name} (#{new_branch})",
        :uri     => uri,
        :branch  => new_branch,
        :command => command,
        :public  => public?
      )

      notifiers.each { |notifier|
        forked.notifiers.create(
          :name    => notifier.name,
          :enabled => notifier.enabled?,
          :config  => notifier.config
        )
      }

      forked
    end

    def github?
      uri.to_s.include?("github.com")
    end

    # TODO lame, there is got to be a better way
    def sorted_builds
      builds(:order => [:created_at.desc])
    end

    def last_build
      sorted_builds.first
    end

    def blank?
      last_build.nil?
    end

    def status
      blank? ? :blank : last_build.status
    end

    def human_status
      ! blank? && last_build.human_status
    end

    private
      def set_permalink
        attribute_set(:permalink,
          (name || "").
          downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
        )
      end
  end
end
