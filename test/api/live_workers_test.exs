defmodule StepFlow.Api.LiveWorkersTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.{Jobs, LiveWorkers, Router, Workflows}
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)

    groups = [
      "administrator",
      "technician",
      "editor",
    ]

    {:ok, workflow} = Workflows.create_workflow(%{
      schema_version: "1.8",
      identifier: "dev_workflow_for_live_workers",
      label: "Dev Workflow for live workers",
      tags: ["dev"],
      icon: "custom_icon",
      is_live: true,
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some-identifier",
      steps: [],
      parameters: [
      ],
      rights: [
        %{
          action: "view",
          groups: groups
        },
        %{
          action: "create",
          groups: groups
        },
        %{
          action: "retry",
          groups: groups
        },
        %{
          action: "abort",
          groups: groups
        },
        %{
          action: "delete",
          groups: groups
        }
      ]
    })

    {:ok, job} = Jobs.create_job(%{
      name: "my_live_step",
      step_id: 666,
      parameters: [],
      workflow_id: workflow.id
    })

    {:ok, _live_worker} = LiveWorkers.create_live_worker(%{
      ips: [
        "127.0.0.1",
        "192.168.1.1"
      ],
      ports: [80, 443],
      instance_id: "12345676890",
      direct_messaging_queue_name: "my_direct_messaging_queue_name",
      job_id: job.id,
    })

    {:ok, _live_worker} = LiveWorkers.create_live_worker(%{
      ips: [
        "127.0.0.1",
        "192.168.1.1"
      ],
      ports: [80, 443],
      instance_id: "9876543210",
      direct_messaging_queue_name: "my_direct_messaging_queue_name",
      job_id: job.id,
      creation_date: DateTime.now!("Etc/UTC")
    })

    {:ok, _live_worker} = LiveWorkers.create_live_worker(%{
      ips: [
        "127.0.0.1",
        "192.168.1.1"
      ],
      ports: [80, 443],
      instance_id: "444444444",
      direct_messaging_queue_name: "my_direct_messaging_queue_name",
      job_id: job.id,
      creation_date: DateTime.now!("Etc/UTC") |> DateTime.add(-3600, :second),
      termination_date: DateTime.now!("Etc/UTC")
    })

    {:ok, _live_worker} = LiveWorkers.create_live_worker(%{
      instance_id: "666666666",
      direct_messaging_queue_name: "my_direct_messaging_queue_name",
      job_id: job.id,
      creation_date: DateTime.now!("Etc/UTC") |> DateTime.add(-3600, :second)
    })

    {:ok, _live_worker} = LiveWorkers.create_live_worker(%{
      instance_id: "999999999",
      direct_messaging_queue_name: "my_direct_messaging_queue_name",
      job_id: job.id,
    })

    :ok
  end

  describe "live_workers" do
    test "GET /live_workers" do
      {status, _headers, body} =
        conn(:get, "/live_workers")
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      assert body |> Jason.decode!() |> Map.get("total") == 5

      {status, _headers, body} =
        conn(:get, "/live_workers", %{"initializing" => true})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      assert body |> Jason.decode!() |> Map.get("total") == 3

      {status, _headers, body} =
        conn(:get, "/live_workers", %{"started" => true})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      assert body |> Jason.decode!() |> Map.get("total") == 1

      {status, _headers, body} =
        conn(:get, "/live_workers", %{"terminated" => true})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      assert body |> Jason.decode!() |> Map.get("total") == 1
    end
  end
end
