defmodule ImapEx.Imap.Connection do
  defstruct [
    :hostname,
    :username,
    :password,
    :socket,
    :mailbox,
    tag: 0,
  ]
end
