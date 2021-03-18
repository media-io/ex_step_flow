defmodule Prometheus.Metrics.WorkflowCollectorTest do
  use ExUnit.Case
  use Plug.Test

  import ExUnit.CaptureIO

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Artifacts
  alias StepFlow.Metrics.WorkflowCollector
  alias StepFlow.Workflows

  doctest StepFlow

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  describe "workflows" do
    @valid_attrs %{
      schema_version: "1.8",
      identifier: "id",
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
        |> Enum.into(@valid_attrs)
        |> Workflows.create_workflow()

      workflow
    end

    test "collect_mf" do
      workflow = workflow_fixture()
      :timer.sleep(1000)

      Artifacts.create_artifact(%{
        resources: %{},
        workflow_id: workflow.id
      })

      IO.inspect(
        capture_io(fn ->
          WorkflowCollector.collect_mf(:workflow_collector, fn mf ->
            :io.format("~p", [mf])
          end)
        end)
      )

      assert capture_io(fn ->
               WorkflowCollector.collect_mf(:workflow_collector, fn mf ->
                 :io.format("~p", [mf])
               end)
             end) == "{'MetricFamily',<<\"step_flow_workflows_created\">>,
                <<\"Number of created workflows since -1 day(s).\">>,'GAUGE',
                [{'Metric',[{'LabelPair',<<\"identifier\">>,<<\"id\">>}],
                           {'Gauge',1},
                           undefined,undefined,undefined,undefined,
                           undefined}]}{'MetricFamily',<<\"step_flow_workflows_error\">>,
                <<\"Number of failed workflows since -1 day(s).\">>,'GAUGE',[]}{'MetricFamily',<<\"step_flow_workflows_completed\">>,
                <<\"Number of completed workflows since -1 day(s).\">>,'GAUGE',
                [{'Metric',[{'LabelPair',<<\"identifier\">>,<<\"id\">>}],
                           {'Gauge',1},
                           undefined,undefined,undefined,undefined,
                           undefined}]}{'MetricFamily',<<\"step_flow_workflows_duration\">>,
                <<\"Average durations of workflows since -1 day(s).\">>,'GAUGE',
                [{'Metric',[{'LabelPair',<<\"identifier\">>,<<\"id\">>}],
                           {'Gauge',1.0},
                           undefined,undefined,undefined,undefined,
                           undefined}]}"
    end
  end
end
