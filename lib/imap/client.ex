defmodule ImapEx.Imap.Client do
  alias ImapEx.Imap.Connection

  use GenServer

  @moduledoc """
  Imap Client GenServer
  """

  def start_link(args) do
    if !Keyword.has_key?(args, :hostname) do
      raise "Missing required argument :hostname"
    end

    GenServer.start_link(__MODULE__, args)
  end

  def login(pid) do
    GenServer.call(pid, :login)
  end

  def logout(pid) do
    GenServer.call(pid, :logout)
  end

  def select(pid, mailbox) do
    GenServer.call(pid, {:select, mailbox})
  end

  @impl true
  def init(args) do
    send(self(), {:initialize, args})
    {:ok, nil}
  end

  @impl true
  def handle_info({:initialize, args}, _state) do
    opts = [packet: :line, active: :once, mode: :binary]

    {:ok, socket} =
      :gen_tcp.connect(args[:hostname], args[:port], opts)

    conn = %Connection{
      hostname: args[:hostname],
      username: args[:username],
      password: args[:password],
      socket: socket,
    }

    {:noreply, conn}
  end

  @impl true
  def handle_info({_socket_type, _socket, msg}, conn) do
    IO.inspect(msg, label: "in the not_misc handle_info")

    if (!conn.received_server_greeting) do
      %{conn | received_server_greeting: true}
      |> send_command("login \"#{conn.username}\" \"#{conn.password}\"")
    end

    {:noreply, conn}
  end

  @impl true
  def handle_info({:server_response, msg}, conn) do
    IO.inspect(msg, label: "S:")
    {:noreply, conn}
  end

  @impl true
  def handle_call(:login, _from, conn) do
    :gen_tcp.send(conn.socket, "#{conn.tag} login \"#{conn.username}\" \"#{conn.password}\"")
    Map.put(conn, :tag, conn.tag + 1)
    {:reply, :ok, conn}
  end

  @impl true
  def handle_call(:logout, _from, conn) do
    send_command(conn, "logout")
    {:reply, :ok, conn}
  end

  @impl true
  def handle_call({:select, mailbox}, _from, conn) do
    send_command(conn, "select #{mailbox}")
    Map.put(conn, :mailbox, mailbox)
    {:reply, :ok, conn}
  end

  defp send_command(conn, command) do
    command = "#{conn.tag} #{command}\r\n"
    Map.put(conn, :tag, conn.tag + 1)

    :gen_tcp.send(conn.socket, command)
    {:ok, packet} = :gen_tcp.recv(conn.socket, 0)

    send(self(), {:server_response, packet})
  end
end
