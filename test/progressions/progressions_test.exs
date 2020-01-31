defmodule StepFlow.ProgressionsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Jobs
  alias StepFlow.Progressions
  alias StepFlow.Workflows
  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  @workflow %{
      identifier: "id",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: []
  }

  test "create job progression" do
    {_, workflow} = Workflows.create_workflow(@workflow)
    {_, job} =
      Jobs.create_job(%{
          name: "job_test",
          step_id: 0,
          workflow_id: workflow.id
      })

    {result, _} =
      Progressions.create_progression(%{
        job_id: job.id,
        datetime: ~N[2020-01-31 09:48:53],
        docker_container_id: "unknown",
        progression: 50
    })

    assert result == :ok

  end
end
