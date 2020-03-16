defmodule StepFlow.Notification do
  @moduledoc """
  Send notifications to endpoint to be forwarded to websockets.
  """

  def send(topic, body) do
    configuration = Application.get_env(:step_flow, StepFlow)

    if Keyword.has_key?(configuration, :endpoint) do
      Keyword.get(configuration, :endpoint).broadcast!("notifications:all", topic, %{body: body})
    end
  end
end
