defmodule StepFlow.RunWorkflows.StepParametersTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.WorkflowDefinitions.WorkflowDefinition

  doctest StepFlow

  describe "workflows" do
    @workflow_definition %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      icon: "custom_icon",
      label: "Workflow with all the possible parameter types",
      tags: ["test"],
      parameters: [],
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          icon: "step_icon",
          label: "My first step",
          work_dir: "/custom/work/directory/",
          parameters: [
            %{
              id: "param",
              type: "boolean",
              default: false,
              value: true
            },
            %{
              id: "source_paths",
              type: "integer",
              default: 1234,
              value: 4321
            },
            %{
              id: "source_paths",
              type: "string",
              default: "1234",
              value: "4321"
            },
            %{
              id: "source_paths",
              type: "credential",
              default: "SAMPLE_TEST",
              value: "KEY_IN_STORE"
            },
            %{
              id: "source_paths",
              type: "array_of_strings",
              value: [
                "my_file_1.mov"
              ]
            },
            %{
              id: "source_paths",
              type: "template",
              value: "some string template"
            },
            %{
              id: "source_paths",
              type: "array_of_templates",
              value: [
                "template example 1",
                "template example 2"
              ]
            },
            %{
              id: "source_paths",
              type: "filter",
              value: %{ends_with: [".ttml", ".wav"]}
            },
            %{
              id: "source_paths",
              type: "select_input",
              value: %{ends_with: [".ttml", ".wav"]}
            },
            %{
              id: "source_paths",
              type: "requirements",
              value: [
                %{
                  paths: ["/path/to/file.txt"]
                }
              ]
            }
          ]
        }
      ]
    }

    test "check parameters type on step" do
      @workflow_definition
      |> Jason.encode!
      |> Jason.decode!
      |> WorkflowDefinition.validate()
    end
  end
end
