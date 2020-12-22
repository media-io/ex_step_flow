defmodule StepFlow.Metrics.WorkflowNumberCollector do
  use Prometheus.Collector
  alias StepFlow.Workflows

  def collect_mf(_registry, callback) do
    scale = Application.get_env(StepFlow.Metrics, :scale, "day")
    delta = Application.get_env(StepFlow.Metrics, :delta, -1)
    counts = Workflows.workflows_number_in_interval(scale, delta)

    callback.(
      create_gauge(
        :step_flow_workflows_number,
        "Number of workflows finished since #{delta} #{scale}(s).",
        counts
      )
    )

    :ok
  end

  def collect_metrics(:step_flow_workflows_number, counts) do
    Prometheus.Model.gauge_metrics(
      Enum.map(counts, fn %{count: count, identifier: identifier} ->
        {[identifier: identifier], count}
      end)
    )
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end
end
