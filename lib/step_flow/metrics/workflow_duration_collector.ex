defmodule StepFlow.Metrics.WorkflowDurationCollector do
  use Prometheus.Collector
  alias StepFlow.Workflows

  def collect_mf(_registry, callback) do
    scale = Application.get_env(StepFlow.Metrics, :scale, "day")
    delta = Application.get_env(StepFlow.Metrics, :delta, -1)
    durations = Workflows.workflows_duration_in_interval(scale, delta)

    callback.(
      create_gauge(
        :step_flow_workflows_duration,
        "Average durations of workflows since #{delta} #{scale}(s).",
        durations
      )
    )

    :ok
  end

  def collect_metrics(:step_flow_workflows_duration, durations) do
    Prometheus.Model.gauge_metrics(
      Enum.map(durations, fn %{duration: duration, identifier: identifier} ->
        {[identifier: identifier], duration}
      end)
    )
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end
end
