defmodule ImapEx.Imap.Connection do
  defstruct [
    :hostname,
    :username,
    :password,
    :socket,
    :mailbox,
    tag: 0,
    received_server_greeting: false
  ]
end
