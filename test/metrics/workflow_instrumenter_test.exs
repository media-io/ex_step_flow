defmodule StepFlow.Metrics.WorkflowInstrumenterTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias Prometheus.Metric
  alias StepFlow.Metrics.WorkflowInstrumenter
  alias StepFlow.Workflows

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  describe "workflows" do
    @workflow %{
      schema_version: "1.8",
      identifier: "identifier",
      version_major: 6,
      version_minor: 5,
      version_micro: 4,
      reference: "some id",
      steps: [],
      rights: [
        %{
          action: "view",
          groups: ["user_view"]
        }
      ]
    }

    def workflow_fixture(attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(@workflow)
        |> Workflows.create_workflow()

      workflow
    end

    test "inc :step_flow_workflows_created" do
      WorkflowInstrumenter.inc(:step_flow_workflows_created, "identifier")

      assert Metric.Counter.value(
               name: :step_flow_workflows_created,
               labels: ["identifier"]
             ) == 1
    end

    test "inc :step_flow_workflows_error" do
      workflow = workflow_fixture()

      WorkflowInstrumenter.inc(:step_flow_workflows_error, workflow.id)

      assert Metric.Counter.value(
               name: :step_flow_workflows_error,
               labels: ["identifier"]
             ) == 1
    end

    test "inc :step_flow_workflows_completed" do
      WorkflowInstrumenter.inc(:step_flow_workflows_completed, "identifier")

      assert Metric.Counter.value(
               name: :step_flow_workflows_completed,
               labels: ["identifier"]
             ) == 1
    end
  end
end
