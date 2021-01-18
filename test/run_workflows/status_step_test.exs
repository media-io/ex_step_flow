defmodule StepFlow.RunWorkflows.StatusStepTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Repo
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "status_steps",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Status steps",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "job_test",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: ["my_file.mov"]
            }
          ]
        },
        %{
          id: 1,
          required_to_start: [0],
          parent_ids: [0],
          name: "job_test",
          icon: "step_icon",
          label: "Second step",
          parameters: []
        }
      ],
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ]
    }

    test "run parallel steps on a same workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)
      StepFlow.HelpersTest.complete_jobs(workflow.id, 0)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 0).completed == 1

      {:ok, "started"} = Step.start_next(workflow)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 1

      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.change_job_status(workflow, 1, :retrying)

      :timer.sleep(1000)

      {:ok, "still_processing"} = Step.start_next(workflow)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 1
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).processing == 0

      StepFlow.HelpersTest.create_progression(workflow, 1)

      {:ok, "still_processing"} = Step.start_next(workflow)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).processing == 1

      StepFlow.HelpersTest.change_job_status(workflow, 1, :retrying)

      {:ok, "still_processing"} = Step.start_next(workflow)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 1
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).processing == 0

      :timer.sleep(1000)

      StepFlow.HelpersTest.check(workflow.id, 1, 1)
      StepFlow.HelpersTest.create_progression(workflow, 1)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).processing == 1

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 2)

      StepFlow.HelpersTest.change_job_status(workflow, 1, :error)

      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).queued == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).processing == 0
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).errors == 1
      assert StepFlow.HelpersTest.get_job_count_status(workflow, 1).completed == 0
    end
  end
end
