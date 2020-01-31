defmodule StepFlow.Amqp.ProgressionConsumerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.ProgressionConsumer

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    [channel: channel]
  end

  @message %{
      job_id: 2,
      datetime: ~N[2020-01-31 09:48:53],
      docker_container_id: "unknown",
      progression: 50
  }

  test "consume a job progression message" , %{channel: channel} do
      tag = "acs"
      result = ProgressionConsumer.consume(channel, tag, false, @message)

      assert result == :ok
  end
end
