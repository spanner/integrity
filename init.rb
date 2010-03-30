$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require ".bundle/environment"
require "integrity"
require "integrity/notifier/email"
require "integrity/notifier/irc"

Integrity.configure do |c|
  c.database  "sqlite3:integrity.db"
  c.directory "builds"
  c.base_url "http://integrity.spanner.org"
  c.log "/var/www/integrity/logs/integrity.log"
  c.build_all!
  c.builder :dj, :adapter => "sqlite3", :database => "dj.db"
  c.user "admin"
  c.pass "testy"
  c.github "SECRET"
end
