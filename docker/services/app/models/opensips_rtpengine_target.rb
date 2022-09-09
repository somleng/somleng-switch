class OpenSIPSRTPEngineTarget < ApplicationRecord
  attr_reader :target_ip

  def initialize(target_ip:, **options)
    super(**options)
    @target_ip = target_ip
  end

  def save!
    create_rtpengine_target unless rtpengine_target_exists?
  end

  def delete!
    delete_rtpengine_target
  end

  private

  def rtpengine_target_exists?
    rtpengine.where(socket:).count.positive?
  end

  def create_rtpengine_target
    rtpengine.insert(socket:, set_id: 0)
  end

  def delete_rtpengine_target
    rtpengine.where(socket:).delete
  end

  def rtpengine
    @rtpengine ||= database_connection.table(:rtpengine)
  end

  def socket
    "udp:#{target_ip}:#{socket_port}"
  end

  def socket_port
    ENV.fetch("MEDIA_PROXY_NG_PORT")
  end
end
