OkComputer::Registry.register "freeswitch", OkComputer::PingCheck.new(
  AppSettings.fetch(:ahn_core_host),
  AppSettings.fetch(:ahn_core_port)
)
