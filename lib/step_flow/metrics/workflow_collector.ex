defmodule StepFlow.Metrics.WorkflowCollector do
  @moduledoc """
  Prometheus metrics collector for workflow duration
  """
  use Prometheus.Collector
  alias StepFlow.Configuration
  alias StepFlow.Workflows
  require Logger

  def collect_mf(_registry, callback) do
    scale = Configuration.get_var_value(StepFlow.Metrics, :scale, "day")
    delta = Configuration.get_var_value(StepFlow.Metrics, :delta, -1)
    creation_statistics = Workflows.get_creation_statistics(scale, delta)
    error_statistics = Workflows.get_error_statistics(scale, delta)
    completed_statistics = Workflows.get_completed_statistics(scale, delta)

    callback.(
      create_gauge(
        :step_flow_workflows_created,
        "Number of created workflows since #{delta} #{scale}(s).",
        creation_statistics
      )
    )

    callback.(
      create_gauge(
        :step_flow_workflows_error,
        "Number of failed workflows since #{delta} #{scale}(s).",
        error_statistics
      )
    )

    callback.(
      create_gauge(
        :step_flow_workflows_completed,
        "Number of completed workflows since #{delta} #{scale}(s).",
        completed_statistics
      )
    )

    callback.(
      create_gauge(
        :step_flow_workflows_duration,
        "Average durations of workflows since #{delta} #{scale}(s).",
        completed_statistics
      )
    )

    :ok
  end

  def collect_metrics(:step_flow_workflows_created, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{count: count, identifier: identifier} ->
        {[identifier: identifier], count}
      end)
    )
  end

  def collect_metrics(:step_flow_workflows_error, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{count: count, identifier: identifier} ->
        {[identifier: identifier], count}
      end)
    )
  end

  def collect_metrics(:step_flow_workflows_completed, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{count: count, identifier: identifier} ->
        {[identifier: identifier], count}
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

  def collect_metrics(:step_flow_workflows_duration, statistics) do
    Prometheus.Model.gauge_metrics(
      Enum.map(statistics, fn %{duration: duration, identifier: identifier} ->
        {[identifier: identifier], duration}
      end)
    )
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end
end
