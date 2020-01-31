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

  test "consume a job progression message", %{channel: channel} do
    tag = "acs"
    {:ok, datetime, 0} = DateTime.from_iso8601("2020-01-31T09:48:53Z")

    result = ProgressionConsumer.consume(channel, tag, false, @message)

    assert result == :ok
  end
end
