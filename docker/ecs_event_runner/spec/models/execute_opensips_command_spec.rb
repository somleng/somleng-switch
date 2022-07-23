require_relative "../spec_helper"

RSpec.describe ExecuteOpenSIPSCommand do
  it "executes an OpenSIPS command" do
    FileUtils.rm_f("/tmp/fifo")
    FileUtils.touch("/tmp/fifo")

    ExecuteOpenSIPSCommand.call(:lb_reload, {}, fifo_name: "/tmp/fifo")

    expect(File.read("/tmp/fifo")).to eq('::{"jsonrpc":"2.0","method":"lb_reload"}')
  end
end
