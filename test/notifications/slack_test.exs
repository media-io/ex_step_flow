defmodule StepFlow.Notifications.SlackTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step
  alias StepFlow.Workflows

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  test "notify Slack channel" do
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
              value: "slack"
            },
            %{
              id: "channel",
              type: "string",
              value: "support"
            },
            %{
              id: "body",
              type: "template",
              value:
                "Workflow #<%= workflow_id %> - {step_name}\n\nFiles generated: <%= inspect source_paths %>"
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
             "message" => "missing slack configuration"
           }
  end
end
