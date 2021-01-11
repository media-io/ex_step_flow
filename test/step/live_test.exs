defmodule StepFlow.LiveTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Repo
  alias StepFlow.Step.Helpers
  alias StepFlow.Step.Launch
  alias StepFlow.Step.LaunchParams
  alias StepFlow.Step.Live
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
    {conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_worker_manager", 1)
      # StepFlow.HelpersTest.consume_messages(channel, "direct_messaging_job_live", 2)
      StepFlow.HelpersTest.close_amqp_connection(conn)
    end)
  end

  describe "live workflow" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "id",
      is_live: true,
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "job_live",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "srt://:9999"
              ]
            },
            %{
              id: "toto",
              type: "string",
              value: "toto"
            },
            %{
              id: "direct_messaging_queue_name",
              type: "string",
              value: "job_live"
            }
          ]
        }
      ],
      rights: [
        %{
          action: "create",
          groups: ["administrator"]
        }
      ]
    }
  end

  def workflow_fixture(workflow, attrs \\ %{}) do
    {:ok, workflow} =
      attrs
      |> Enum.into(workflow)
      |> Workflows.create_workflow()

    workflow
  end

  test "generate message" do
    workflow =
      workflow_fixture(@workflow_definition)
      |> Repo.preload([:artifacts, :jobs])

    first_file = "srt://:9999"
    step = @workflow_definition.steps |> List.first()
    dates = Helpers.get_dates()

    source_paths = Launch.get_source_paths(workflow, step, dates)
    assert source_paths == ["srt://:9999"]

    current_date_time =
      Timex.now()
      |> Timex.format!("%Y_%m_%d__%H_%M_%S", :strftime)

    current_date =
      Timex.now()
      |> Timex.format!("%Y_%m_%d", :strftime)

    launch_params =
      LaunchParams.new(
        workflow,
        step,
        %{date_time: current_date_time, date: current_date},
        first_file
      )

    Live.create_job_live(source_paths, launch_params)

    workflow_id = workflow.id
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    job = Jobs.get_by(%{"workflow_id" => workflow_id, "step_id" => step_id})

    job_id = job.id

    # Created

    result =
      CommonEmitter.publish_json(
             "worker_created",
             0,
             %{
               direct_messaging_queue_name: "direct_messaging_job_live"
             },
             "job_response"
           )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job_id).state == :ready_to_init

    # Init

    result =
      CommonEmitter.publish_json(
             "worker_initialized",
             0,
             %{
               job_id: job_id
             },
             "job_response"
           )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job_id).state == :ready_to_start

    # Start

    result =
      CommonEmitter.publish_json(
             "worker_started",
             0,
             %{
               job_id: job_id
             },
             "job_response"
           )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job_id).state == :processing

    # Delete

    result =
      CommonEmitter.publish_json(
             "worker_terminated",
             0,
             %{
               job_id: job_id
             },
             "job_response"
           )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job_id).state == :completed
  end
end
