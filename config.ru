require 'rubygems'
require 'bundler/setup'
require "init"

BUILD_PATH = "/usr/local/sbin:/usr/local/bin"
BUILD_GEM_HOME = "/usr/lib/ruby/gems/1.8"

run Integrity.app
