defmodule StepFlow.RunWorkflows.SkippedStepsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflows" do
    @workflow_definition %{
      identifier: "skipped_steps",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Skipped steps",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: []
            }
          ]
        },
        %{
          id: 1,
          required_to_start: [0],
          parent_ids: [0],
          name: "first_parallel_step",
          icon: "step_icon",
          label: "First parallel step",
          parameters: []
        },
        %{
          id: 2,
          required_to_start: [0],
          parent_ids: [0],
          name: "second_parallel_step",
          icon: "step_icon",
          label: "Second parallel step",
          parameters: []
        },
        %{
          id: 3,
          required_to_start: [1, 2],
          parent_ids: [1, 2],
          name: "joined_last_step",
          icon: "step_icon",
          label: "Joined last step",
          parameters: []
        }
      ]
    }

    test "run parallel steps on a same workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "completed"} = Step.start_next(workflow)
    end
  end
end
