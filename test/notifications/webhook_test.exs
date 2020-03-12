defmodule StepFlow.Notifications.WebhookTest do
  use ExUnit.Case
  use Plug.Test

  import FakeServer

  alias Ecto.Adapters.SQL.Sandbox
  alias FakeServer.Response
  alias StepFlow.Step
  alias StepFlow.Workflows

  setup do
    # Explicitly get a connection before each test
    Sandbox.checkout(StepFlow.Repo)
  end

  test_with_server "notify HTTP endpoint" do
    route "/notification/test_work_dir", fn(_) -> Response.ok!("{\"status\": \"ok\"}") end

    workflow_definition = %{
      identifier: "notification",
      version_major: 1,
      version_minor: 0,
      version_micro: 2,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "notification_step",
          mode: "notification",
          parameters: [
            %{
              id: "service",
              type: "string",
              value: "webhook"
            },
            %{
              id: "url",
              type: "template",
              value: "http://#{FakeServer.address}/notification{work_directory}"
            },
            %{
              id: "method",
              type: "string",
              value: "POST"
            },
            %{
              id: "body",
              type: "template",
              value: "{\"workflow_id\": {workflow_id}}"
            }
          ]
        }
      ]
    }

    {:ok, workflow} = Workflows.create_workflow(workflow_definition)
    {:ok, "completed"} =
      Step.start_next(workflow)

    jobs = StepFlow.HelpersTest.get_jobs(workflow.id, "notification_step")

    assert length(jobs) == 1

    status =
      jobs
      |> List.first
      |> Map.get(:status)

    assert length(status) == 1
    assert :completed == status |> List.first |> Map.get(:state)
  end

  test_with_server "notify HTTP endpoint in error" do
    route "/bad_endpoint", fn(_) -> Response.ok!("{\"status\": \"ok\"}") end

    workflow_definition = %{
      identifier: "notification",
      version_major: 1,
      version_minor: 0,
      version_micro: 2,
      reference: "some id",
      steps: [
        %{
          id: 0,
          name: "notification_step",
          mode: "notification",
          parameters: [
            %{
              id: "service",
              type: "string",
              value: "webhook"
            },
            %{
              id: "url",
              type: "template",
              value: "http://#{FakeServer.address}/notification{work_directory}"
            },
            %{
              id: "method",
              type: "string",
              value: "POST"
            },
            %{
              id: "body",
              type: "template",
              value: "{\"workflow_id\": {workflow_id}}"
            }
          ]
        }
      ]
    }

    {:ok, workflow} = Workflows.create_workflow(workflow_definition)
    {:ok, "created"} =
      Step.start_next(workflow)

    jobs = StepFlow.HelpersTest.get_jobs(workflow.id, "notification_step")

    assert length(jobs) == 1

    status =
      jobs
      |> List.first
      |> Map.get(:status)

    assert length(status) == 1
    assert :error == status |> List.first |> Map.get(:state)
    assert status |> List.first |> Map.get(:description) == %{"message" => "response status code: 404 with body: \"\""}
  end
end
