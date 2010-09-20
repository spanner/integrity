require "webrat"
require "rack/test"
require "webmock/test_unit"

require "helper"
require "helper/acceptance/repo"

Rack::Test::DEFAULT_HOST.replace("www.example.com")

# TODO
Webrat::Session.class_eval {
  def redirect?
    [301, 302, 303, 307].include?(response_code)
  end
}

module AcceptanceHelper
  include TestHelper

  def git_repo(name)
    repo = GitRepo.new(name.to_s)

    unless File.directory?(repo.uri)
      repo.create
    end

    repo
  end

  def login_as(user, password)
    def AcceptanceHelper.logged_in; true; end
    rack_test_session.basic_authorize(user, password)
    Integrity::App.before { login_required if AcceptanceHelper.logged_in }
  end

  def log_out
    def AcceptanceHelper.logged_in; false; end
    rack_test_session.header("Authorization", nil)
  end

  # thanks http://github.com/ichverstehe
  def mock_socket
    socket, server = MockSocket.new, MockSocket.new
    socket.in, server.out = IO.pipe
    server.in, socket.out = IO.pipe

    stub(TCPSocket).open(anything, anything) {socket}
    server
  end

  class MockSocket
    attr_accessor :in, :out
    def gets() @in.gets end
    def puts(m) @out.puts(m) end
    def eof?() true end
    def close() end
  end
end

class Test::Unit::AcceptanceTestCase < IntegrityTest
  include FileUtils
  include AcceptanceHelper

  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
  include Webrat::HaveTagMatcher
  include WebMock

  Webrat::Methods.delegate_to_session :response_code

  attr_reader :app

  def self.story(*a); end

  class << self
    alias_method :scenario, :test
  end

  class MockBuilder
    def self.enqueue(build)
      build.run!
    end
  end

  setup do
    Integrity::App.set(:environment, :test)
    Webrat.configure { |c| c.mode = :rack }
    # TODO
    Integrity.config.instance_variable_set(:@builder, MockBuilder)
    @app = Integrity.app

    if Integrity.config.directory.directory?
      Integrity.config.directory.rmtree
    end

    Integrity.config.directory.mkdir
    log_out
  end
end
