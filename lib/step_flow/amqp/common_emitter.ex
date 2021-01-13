defmodule StepFlow.Amqp.CommonEmitter do
  @moduledoc """
  A common emitter to send job orders to workers.
  """
  require Logger
  alias StepFlow.Amqp.Connection

  @doc """
  Publish a message.

  Example:

  ```elixir
  StepFlow.Amqp.CommonEmitter.publish_json("my_rabbit_mq_queue", "{\\\"key\\\": \\\"value\\\"}")
  ```

  """
  def publish(queue, message, options \\ [], exchange \\ "job_submit") do
    Connection.publish(queue, message, options, exchange)
  end

  @doc """
  Publish a message using JSON serialization before send it.

  Example:

  ```elixir
  StepFlow.Amqp.CommonEmitter.publish_json("my_rabbit_mq_queue", 0, %{key: "value"})
  ```

  """
  def publish_json(queue, priority, message, exchange \\ "job_submit") do
    message =
      message
      |> check_message_parameters
      |> Jason.encode!()

    options = [
      priority: min(priority, 100)
    ]

    publish(queue, message, options, exchange)
  end

  defp check_message_parameters(message) do
    parameters =
      message
      |> StepFlow.Map.get_by_key_or_atom(:parameters, [])
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :type) != "filter"
      end)

    StepFlow.Map.replace_by_atom(message, :parameters, parameters)
  end
end
