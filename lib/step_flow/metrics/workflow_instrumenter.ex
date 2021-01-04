defmodule StepFlow.Metrics.WorkflowInstrumenter do
  @moduledoc """
  Prometheus metrics instrumenter to call workflow metric collectors
  """
  use Prometheus.Metric

  def setup do
    Prometheus.Registry.register_collector(StepFlow.Metrics.WorkflowCollector)
  end
end
