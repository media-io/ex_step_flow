defmodule StepFlow.Metrics.WorkflowInstrumenter do
  @moduledoc """
  Prometheus metrics instrumenter to call workflow metric collectors
  """
  alias StepFlow.Workflows
  use Prometheus.Metric

  def setup do
    Prometheus.Registry.register_collector(StepFlow.Metrics.WorkflowCollector)

    Counter.declare(
      name: :step_flow_workflows_created,
      help: "Number of created workflows.",
      labels: [:identifier]
    )

    Counter.declare(
      name: :step_flow_workflows_error,
      help: "Number of failed workflows.",
      labels: [:identifier]
    )

    Counter.declare(
      name: :step_flow_workflows_completed,
      help: "Number of completed workflows.",
      labels: [:identifier]
    )
  end

  def inc(:step_flow_workflows_created, identifier) do
    if StepFlow.Configuration.metrics_enabled?() do
      Counter.inc(
        name: :step_flow_workflows_created,
        labels: [identifier]
      )
    end
  end

  def inc(:step_flow_workflows_error, workflow_id) do
    if StepFlow.Configuration.metrics_enabled?() do
      with %{identifier: identifier} <- Workflows.get_workflow!(workflow_id) do
        Counter.inc(
          name: :step_flow_workflows_error,
          labels: [identifier]
        )
      end
    end
  end

  def inc(:step_flow_workflows_completed, identifier) do
    if StepFlow.Configuration.metrics_enabled?() do
      Counter.inc(
        name: :step_flow_workflows_completed,
        labels: [identifier]
      )
    end
  end
end
