defmodule StepFlow.LiveWorkflowTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.LiveWorkers
  alias StepFlow.Repo
  alias StepFlow.Step
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
    {conn, channel} = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_worker_manager", 2)
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
          skip_destination_path: true,
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
              id: "destination_path",
              type: "string",
              value: "srt://:8888"
            }
          ]
        },
        %{
          id: 1,
          parent_ids: [0],
          skip_destination_path: true,
          name: "job_live",
          parameters: [
            %{
              id: "destination_path",
              type: "string",
              value: "srt://:7777"
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

  test "test full live workflow end to end" do
    workflow =
      workflow_fixture(@workflow_definition)
      |> Repo.preload([:artifacts, :jobs])

    step = @workflow_definition.steps |> List.first()

    {:ok, "started"} = Step.start_next(workflow)

    workflow_id = workflow.id
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    job = Jobs.get_by(%{"workflow_id" => workflow_id, "step_id" => step_id})

    direct_messaging_queue_name_step_0 =
      StepFlow.Map.get_by_key_or_atom(job, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "direct_messaging_queue_name"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    job_id = job.id

    {_, _} =
      LiveWorkers.create_live_worker(%{
        job_id: job_id,
        direct_messaging_queue_name: direct_messaging_queue_name_step_0,
        ips: ["1.2.3.4"],
        ports: ["8888"],
        creation_date: ~N[2020-01-31 09:48:53]
      })

    step = @workflow_definition.steps |> List.last()
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    job2 = Jobs.get_by(%{"workflow_id" => workflow_id, "step_id" => step_id})

    direct_messaging_queue_name_step_1 =
      StepFlow.Map.get_by_key_or_atom(job2, :parameters)
      |> Enum.filter(fn param ->
        StepFlow.Map.get_by_key_or_atom(param, :id) == "direct_messaging_queue_name"
      end)
      |> List.first()
      |> StepFlow.Map.get_by_key_or_atom(:value)

    job2_id = job2.id

    {_, _} =
      LiveWorkers.create_live_worker(%{
        job_id: job2_id,
        direct_messaging_queue_name: direct_messaging_queue_name_step_1
      })

    # Created

    result =
      CommonEmitter.publish_json(
        "worker_created",
        0,
        %{
          direct_messaging_queue_name: direct_messaging_queue_name_step_0
        },
        "job_response"
      )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job_id).state == :ready_to_init

    result =
      CommonEmitter.publish_json(
        "worker_created",
        0,
        %{
          direct_messaging_queue_name: direct_messaging_queue_name_step_1
        },
        "job_response"
      )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job2_id).state == :ready_to_init

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

    result =
      CommonEmitter.publish_json(
        "worker_initialized",
        0,
        %{
          job_id: job2_id
        },
        "job_response"
      )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job2_id).state == :ready_to_start

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

    result =
      CommonEmitter.publish_json(
        "worker_started",
        0,
        %{
          job_id: job2_id
        },
        "job_response"
      )

    assert result == :ok

    :timer.sleep(1000)
    assert StepFlow.HelpersTest.get_job_last_status(job2_id).state == :processing

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

    result =
      CommonEmitter.publish_json(
        "worker_terminated",
        0,
        %{
          job_id: job2_id
        },
        "job_response"
      )

    assert result == :ok

    :timer.sleep(1000)
  end
end
