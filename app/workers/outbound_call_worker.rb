class OutboundCallWorker < ApplicationWorker
  def perform(_sqs_msg, body)
    puts body
  end
end
