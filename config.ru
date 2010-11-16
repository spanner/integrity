require 'rubygems'
require 'bundler/setup'
require "init"

BUILD_PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
BUILD_GEM_PATH = "/usr/lib/ruby/gems/1.8"

run Integrity.app
