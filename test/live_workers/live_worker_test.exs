defmodule StepFlow.LiveWorkers.LiveWorkerTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.LiveWorkers

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    {conn, _channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.close_amqp_connection(conn)
    end)
  end

  test "create and get live worker structure" do
    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: 0,
        direct_messaging_queue_name: "direct_messaging_job_live"
      })

    assert live_worker.job_id == 0
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_live"

    {_, _} =
      LiveWorkers.create_live_worker(%{
        job_id: 1,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    live_worker = LiveWorkers.get_by(%{"job_id" => 1})

    assert live_worker.job_id == 1
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_test"
  end

  test "create and update live worker structure" do
    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: 1,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    {_, live_worker} =
      LiveWorkers.update_live_worker(live_worker, %{
        "direct_messaging_queue_name" => "direct_messaging_job_toto"
      })

    assert live_worker.job_id == 1
    assert live_worker.direct_messaging_queue_name == "direct_messaging_job_toto"
  end

  test "changeset live worker structure" do
    {_, live_worker} =
      LiveWorkers.create_live_worker(%{
        job_id: 1,
        direct_messaging_queue_name: "direct_messaging_job_test"
      })

    LiveWorkers.delete_live_worker(live_worker)

    live_worker = LiveWorkers.get_by(%{"job_id" => 1})

    assert live_worker == nil
  end
end
