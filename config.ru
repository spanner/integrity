require 'rubygems'
require 'bundler/setup'
require "init"

BUILD_ENV = "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin GEM_PATH=/usr/lib/ruby/gems/1.8"
BUILD_USER = 'spanner'

run Integrity.app
