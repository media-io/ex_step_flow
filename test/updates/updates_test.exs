defmodule StepFlow.UpdatesTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Updates
  alias StepFlow.Workflows
  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  @workflow %{
    schema_version: "1.8",
    identifier: "id",
    version_major: 6,
    version_minor: 5,
    version_micro: 4,
    reference: "some id",
    steps: [],
    rights: [
      %{
        action: "create",
        groups: ["administrator"]
      }
    ]
  }

  test "create job update" do
    {_, workflow} = Workflows.create_workflow(@workflow)

    {_, job} =
      Jobs.create_job(%{
        name: "job_test",
        step_id: 0,
        workflow_id: workflow.id,
        parameters: [
          %{
            "id" => "destination_path",
            "type" => "string",
            "value" => "/test_work_dir/437/my_file.mov"
          }
        ]
      })

    {result, _} =
      Updates.create_update(%{
        job_id: job.id,
        datetime: ~N[2020-01-31 09:48:53],
        parameters: [%{destination_path: "/test_work_dir/767/my_file.mov"}]
      })

    assert result == :ok
  end
end
