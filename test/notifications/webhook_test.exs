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
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  test_with_server "notify HTTP endpoint" do
    route("/notification/test_work_dir", fn query ->
      if Map.get(query.headers, "content-type") == "application/json" do
        Response.ok!(~s({"status": "ok"}))
      else
        Response.no_content!()
      end
    end)

    workflow_definition = %{
      schema_version: "1.8",
      identifier: "notification",
      version_major: 1,
      version_minor: 0,
      version_micro: 2,
      reference: "some id",
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ],
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
              value: "http://#{FakeServer.address()}/notification{work_directory}"
            },
            %{
              id: "method",
              type: "string",
              value: "POST"
            },
            %{
              id: "headers",
              type: "string",
              value: ~s({"content-type": "application/json"})
            },
            %{
              id: "body",
              type: "template",
              value: ~s({"workflow_id": {workflow_id}})
            }
          ]
        }
      ]
    }

    {:ok, workflow} = Workflows.create_workflow(workflow_definition)
    {:ok, "completed"} = Step.start_next(workflow)

    jobs = StepFlow.HelpersTest.get_jobs(workflow.id, 0)

    assert length(jobs) == 1

    status =
      jobs
      |> List.first()
      |> Map.get(:status)

    assert length(status) == 1
    assert :completed == status |> List.first() |> Map.get(:state)
  end

  @tag capture_log: true
  test_with_server "notify HTTP endpoint in error" do
    route("/bad_endpoint", fn _ -> Response.ok!(~s({"status": "ok"})) end)

    workflow_definition = %{
      schema_version: "1.8",
      identifier: "notification",
      version_major: 1,
      version_minor: 0,
      version_micro: 2,
      reference: "some id",
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ],
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
              value: "http://#{FakeServer.address()}/notification{work_directory}"
            },
            %{
              id: "method",
              type: "string",
              value: "POST"
            },
            %{
              id: "body",
              type: "template",
              value: ~s({"workflow_id": {workflow_id}})
            }
          ]
        }
      ]
    }

    {:ok, workflow} = Workflows.create_workflow(workflow_definition)
    {:ok, "started"} = Step.start_next(workflow)

    jobs = StepFlow.HelpersTest.get_jobs(workflow.id, 0)

    assert length(jobs) == 1

    status =
      jobs
      |> List.first()
      |> Map.get(:status)

    assert length(status) == 1
    assert :error == status |> List.first() |> Map.get(:state)

    assert status |> List.first() |> Map.get(:description) == %{
             "message" => ~s(response status code: 404 with body: "")
           }
  end
end
