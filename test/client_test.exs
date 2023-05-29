defmodule ClientTest do
  use ExUnit.Case
  alias ImapEx.Imap.Client

  describe "start_link/1" do
    @valid_args [hostname: 'localhost', port: 143]
    @invalid_args [hostname: 'bad_host', port: 0]

    test "with valid args creates a connection" do
      {:ok, pid} = Client.start_link(@valid_args) 
      assert is_pid(pid)
    end

    @tag :capture_log
    test "with invalid args stops GenServer" do
      Process.flag(:trap_exit, true)
      Client.start_link(@invalid_args)

      assert_receive({:EXIT, _pid, _reason})
    end
  end
end
