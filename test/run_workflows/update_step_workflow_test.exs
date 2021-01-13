defmodule StepFlow.RunWorkflows.UpdateStepTest do
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
            },
            %{
              id: "test",
              type: "string",
              value: "toto"
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
          parameters: [
            %{
              id: "audio",
              type: "string",
              value: "my_file.wav"
            },
            %{
              id: "video",
              type: "string",
              value: "my_file.mov"
            },
            %{
              id: "disco",
              type: "string",
              value: "my_file.dsc"
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

    test "run parallel steps on a same workflow" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, 0, 1)

      StepFlow.HelpersTest.create_update(workflow, 0, [
        %{
          id: "test",
          type: "string",
          value: "tata"
        }
      ])

      StepFlow.HelpersTest.complete_jobs(workflow.id, 0)

      parameters = StepFlow.HelpersTest.get_parameter_value_list(workflow, 0)

      assert Enum.at(parameters, 1) == "tata"

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1, 1)

      StepFlow.HelpersTest.create_update(workflow, 1, [
        %{
          id: "video",
          type: "string",
          value: "my_new_file.mov"
        }
      ])

      {:ok, "still_processing"} = Step.start_next(workflow)

      parameters = StepFlow.HelpersTest.get_parameter_value_list(workflow, 1)

      assert Enum.at(parameters, 1) == "my_new_file.mov"

      :timer.sleep(1000)

      StepFlow.HelpersTest.check(workflow.id, 1, 1)

      StepFlow.HelpersTest.create_update(workflow, 1, [
        %{
          id: "audio",
          type: "string",
          value: "audio_file.wav"
        },
        %{
          id: "video",
          type: "string",
          value: "video_file.mov"
        },
        %{
          id: "disco",
          type: "string",
          value: "disco_file.dsc"
        }
      ])

      {:ok, "still_processing"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 2)

      parameters = StepFlow.HelpersTest.get_parameter_value_list(workflow, 1)

      assert Enum.at(parameters, 0) == "audio_file.wav"
      assert Enum.at(parameters, 1) == "video_file.mov"
      assert Enum.at(parameters, 2) == "disco_file.dsc"
    end
  end
end
