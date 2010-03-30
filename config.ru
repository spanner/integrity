require "init"
run Integrity.app
map "/cc" do
  run Integrity::Integritray::App
end
