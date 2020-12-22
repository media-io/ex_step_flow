defmodule StepFlow.Metrics.WorkflowInstrumenter do
  use Prometheus.Metric

  def setup() do
    Prometheus.Registry.register_collector(StepFlow.Metrics.WorkflowDurationCollector)
    Prometheus.Registry.register_collector(StepFlow.Metrics.WorkflowNumberCollector)
  end
end
