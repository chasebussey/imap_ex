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

  describe "login/3" do
    @server_args [hostname: 'localhost', port: 143]
    @valid_args [username: "test", password: "password123"]
    @invalid_args [username: "test", password: "password345"]

    test "with valid args returns OK msg" do
      {:ok, pid} = Client.start_link(@server_args)

      expected_result = {:ok, "Logged in"}
      assert Client.login(pid, @valid_args[:username], @valid_args[:password]) == expected_result
    end

    test "with invalid args returns NO msg" do
      {:ok, pid} = Client.start_link(@server_args)
      
      expected_result = {:error, "Authentication failed"}
      assert Client.login(pid, @invalid_args[:username], @invalid_args[:password]) == expected_result
    end
  end
end
