# See: https://opensips.org/html/docs/modules/devel/mi_fifo.html

require "json"

class ExecuteOpenSIPSCommand < ApplicationWorkflow
  JSON_RPC_VERSION = "2.0".freeze

  attr_reader :command, :params, :fifo_name, :reply_fifo_name

  def initialize(command, params = {}, fifo_name: ENV.fetch("OPENSIPS_MI_FIFO_NAME"))
    @command = command
    @params = params
    @fifo_name = fifo_name
    @reply_fifo_name = nil
  end

  def call
    fifo_write
  end

  private

  def fifo_write
    File.write(fifo_name, fifo_command, mode: "a")
  end

  def fifo_command
    payload = {}
    payload[:jsonrpc] = JSON_RPC_VERSION
    payload[:method] = command.to_s
    payload[:params] = params if params.any?
    ":#{reply_fifo_name}:#{payload.to_json}"
  end
end
