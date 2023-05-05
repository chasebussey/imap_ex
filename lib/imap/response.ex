defmodule ImapEx.Imap.Response do
  
  defstruct [:tag, :status, :response_code, :message]

  @response_pattern ~r/(?<tag>\S+) (?<status>OK|NO|BAD|PREAUTH|BYE) (?<response_code>\[.*\]) (?<message>.*)/

  def parse_response(response) do
    captures = Regex.named_captures(@response_pattern, response)

    %__MODULE__{
      tag: captures["tag"], 
      status: captures["status"],
      response_code: captures["response_code"],
      message: captures["message"]
    }
  end
end
