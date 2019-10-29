defmodule StepFlow.Notification do
  @moduledoc """
  Send notifications to endpoint to be forwarded to websockets.
  """

  def send(topic, body) do
    endpoint = Application.get_env(:step_flow, :endpoint)

    if endpoint do
      endpoint.broadcast!("notifications:all", topic, %{body: body})
    end
  end
end
