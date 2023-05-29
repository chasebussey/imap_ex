defmodule ImapEx.Imap.Connection do
  defstruct [
    :hostname,
    :username,
    :socket,
    :mailbox,
    :last_status,
    tag: 0,
  ]
end
