defmodule StepFlow.RunWorkflows.TemplateWithSpecialParamsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Step

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    channel = StepFlow.HelpersTest.get_amqp_connection()

    on_exit(fn ->
      StepFlow.HelpersTest.consume_messages(channel, "job_queue_not_found", 1)
    end)

    :ok
  end

  describe "workflows" do
    @workflow_definition %{
      schema_version: "1.8",
      identifier: "template_with_special_params",
      label: "Check template with special params",
      tags: ["test"],
      icon: "custom_icon",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some-identifier",
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
              value: ["my_file.mov"]
            },
            %{
              id: "special_file",
              type: "template",
              store: "BACKEND",
              default: "{workflow_reference}/{date_time}/toto",
              value: "{workflow_reference}/{date_time}/toto"
            },
            %{
              id: "several_special_files",
              type: "array_of_templates",
              store: "BACKEND",
              default: [
                "{workflow_reference}/{date_time}/tata",
                "{workflow_reference}/{date_time}/titi"
              ],
              value: [
                "{workflow_reference}/{date_time}/tata",
                "{workflow_reference}/{date_time}/titi"
              ]
            }
          ]
        }
      ],
      parameters: [],
      rights: [
        %{
          action: "create",
          groups: ["adminitstrator"]
        }
      ]
    }

    test "run template with special parameters" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)

      step_params =
        StepFlow.Jobs.list_jobs(%{
          "job_type" => "my_first_step",
          "workflow_id" => workflow.id |> Integer.to_string(),
          "size" => 50
        })
        |> Map.get(:data)
        |> List.first()
        |> Map.get(:parameters)

      special_file =
        step_params
        |> Enum.filter(fn parameter -> Map.get(parameter, "id") == "special_file" end)
        |> List.first()

      assert map_size(special_file) == 4

      special_file_filename =
        special_file
        |> Map.get("value")
        |> String.split("/")

      assert length(special_file_filename) == 3
      assert special_file_filename |> List.first() == "some-identifier"
      assert special_file_filename |> List.last() == "toto"

      several_special_files =
        step_params
        |> Enum.filter(fn parameter -> Map.get(parameter, "id") == "special_file" end)
        |> List.first()

      assert map_size(several_special_files) == 4

      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 1)
    end
  end
end
