defmodule StepFlow.RunWorkflows.SourcePathsTemplateTest do
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
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some-identifier",
      icon: "custom_icon",
      label: "Source paths template",
      tags: ["test"],
      steps: [
        %{
          id: 0,
          name: "my_first_step",
          mode: "one_for_many",
          icon: "step_icon",
          label: "My first step",
          parameters: [
            %{
              id: "source_paths",
              type: "array_of_templates",
              value: [
                "{work_directory}/{workflow_id}",
                "{work_directory}/folder"
              ]
            }
          ]
        }
      ],
      parameters: [],
      rights: [
        %{
          action: "create",
          groups: ["administrator"]
        }
      ]
    }

    test "run destination path with template" do
      workflow = StepFlow.HelpersTest.workflow_fixture(@workflow_definition)

      {:ok, "started"} = Step.start_next(workflow)

      StepFlow.HelpersTest.check(workflow.id, 1)
      StepFlow.HelpersTest.check(workflow.id, "my_first_step", 1)

      parameters =
        StepFlow.Jobs.list_jobs(%{
          "job_type" => "my_first_step",
          "workflow_id" => workflow.id |> Integer.to_string(),
          "size" => 50
        })
        |> Map.get(:data)
        |> List.first()
        |> Map.get(:parameters)

      directories = ["/test_work_dir/" <> Integer.to_string(workflow.id), "/test_work_dir/folder"]

      assert parameters == [
               %{
                 "id" => "source_paths",
                 "type" => "array_of_strings",
                 "value" => directories
               },
               %{
                 "id" => "requirements",
                 "type" => "requirements",
                 "value" => %{"paths" => directories}
               }
             ]

      StepFlow.HelpersTest.complete_jobs(workflow.id, "my_first_step")

      {:ok, "completed"} = Step.start_next(workflow)
      StepFlow.HelpersTest.check(workflow.id, 1)
    end
  end
end
