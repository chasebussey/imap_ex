defmodule ImapEx.Imap.Connection do
  defstruct [
    :hostname,
    :username,
    :password,
    :socket,
    :mailbox,
    :last_status,
    tag: 0,
  ]
end
