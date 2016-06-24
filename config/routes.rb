require 'call_controllers/call_controller'

Adhearsion.router do

  # Specify your call routes, directing calls with particular attributes to a controller

  route 'default', CallController
end
