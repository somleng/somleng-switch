ECSEvent = Data.define(
  :task_running?, :task_stopped?, :eni_attached?, :eni_deleted?, :eni_private_ip,
  :private_ip, :public_ip, :group, :family, :event_type, :region, :cluster
)
