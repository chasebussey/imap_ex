defmodule ImapEx.Imap.Client do
  alias ImapEx.Imap.Connection
  alias ImapEx.Imap.Response

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

  def login(pid, username, password) do
    GenServer.call(pid, {:login, username: username, password: password})
  end

  def logout(pid) do
    GenServer.cast(pid, :logout)
  end

  def select(pid, mailbox) do
    GenServer.cast(pid, {:select, mailbox})
  end

  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  @impl true
  def init(args) do
    send(self(), {:initialize, args})
    {:ok, nil}
  end

  @impl true
  def handle_info({:initialize, args}, _state) do
    opts = [packet: :line, active: :false, mode: :binary]

    case :gen_tcp.connect(args[:hostname], args[:port], opts) do
      {:ok, socket} -> {:noreply,
        %Connection{
          hostname: args[:hostname],
          username: args[:username],
          socket: socket
        }
        |> receive_response()
      }

      {:error, reason} -> {:stop, reason, nil}
    end
  end

  @impl true
  def handle_info({:tcp, _socket, msg}, conn) do
    IO.inspect(msg, label: "S")

    {:noreply, conn}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, conn) do
    {:noreply, conn}
  end

  @impl true
  def handle_call(:get_status, _from, conn) do
    {:reply, conn.last_status, conn}
  end

  @impl true
  def handle_call({:login, username: username, password: password}, _from, conn) do
    conn = 
      conn
      |> send_command("login #{username} #{password}")
      |> receive_response()

    case conn.last_status do
      "OK" -> {:reply, {:ok, "Logged in"}, conn}
      "NO" -> {:reply, {:error, "Authentication failed"}, conn}
      "BAD" -> {:reply, {:error, "Malformed request"}, conn}
      _ -> {:reply, {:error, "An unknown error occurred"}, conn}
    end
  end

  @impl true
  def handle_cast(:logout, conn) do
    send_command(conn, "logout")
    {:noreply, conn}
  end

  @impl true
  def handle_cast({:select, mailbox}, conn) do
    send_command(conn, "select #{mailbox}")
    Map.put(conn, :mailbox, mailbox)
    {:noreply, conn}
  end

  defp send_command(conn, command) do
    command = "#{conn.tag} #{command}\r\n"
    conn = Map.put(conn, :tag, conn.tag + 1)

    IO.inspect(command, label: "sending command")

    :gen_tcp.send(conn.socket, command)

    conn
  end

  defp receive_response(conn) do
    {:ok, raw_response} = :gen_tcp.recv(conn.socket, 0, 10000)
    response = Response.parse_response(raw_response)

    Map.put(conn, :last_status, response.status)
  end
end
