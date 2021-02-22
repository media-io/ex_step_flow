defmodule StepFlow.Metrics.WorkflowCollector do
  @moduledoc """
  Prometheus metrics collector for workflow duration
  """
  use Prometheus.Collector
  alias StepFlow.Configuration
  alias StepFlow.Workflows

  def collect_mf(_registry, callback) do
    scale = Configuration.get_var_value(StepFlow.Metrics, :scale, "day")
    delta = Configuration.get_var_value(StepFlow.Metrics, :delta, -1)
    statistics = Workflows.get_statistics_per_identifier(scale, delta)

    callback.(
      create_gauge(
        :step_flow_workflows_duration,
        "Average durations of workflows since #{delta} #{scale}(s).",
        statistics
      )
    )

    callback.(
      create_gauge(
        :step_flow_workflows_number,
        "Number of workflows finished since #{delta} #{scale}(s).",
        statistics
      )
    )

    :ok
  end

  def collect_metrics(:step_flow_workflows_duration, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{duration: duration, identifier: identifier} ->
        {[identifier: identifier], duration}
      end)
    )
  end

  def collect_metrics(:step_flow_workflows_number, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{count: count, identifier: identifier} ->
        {[identifier: identifier], count}
      end)
    )
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end
end
