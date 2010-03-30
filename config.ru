require "init"
require 'integrity/integritray'

map "/cc" do
  run Integrity::Integritray::App
end

run Integrity.app
