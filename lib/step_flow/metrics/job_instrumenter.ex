defmodule StepFlow.Metrics.JobInstrumenter do
  @moduledoc """
  Prometheus metrics instrumenter to call jobs metric collectors
  """
  use Prometheus.Metric

  def setup do
    Counter.declare(
      name: :step_flow_jobs_created,
      help: "Number of created jobs.",
      labels: [:name]
    )

    Counter.declare(
      name: :step_flow_jobs_error,
      help: "Number of failed jobs.",
      labels: [:name]
    )

    Counter.declare(
      name: :step_flow_jobs_completed,
      help: "Number of completed jobs.",
      labels: [:name]
    )

    Gauge.declare(
      name: :step_flow_jobs_processing,
      help: "Number of sockets checked out from the pool",
      labels: [:name]
    )
  end

  def inc(:step_flow_jobs_created, job_name) do
    Counter.inc(
      name: :step_flow_jobs_created,
      labels: [job_name]
    )

    Gauge.inc(
      name: :step_flow_jobs_processing,
      labels: [job_name]
    )
  end

  def inc(:step_flow_jobs_error, job_name) do
    Counter.inc(
      name: :step_flow_jobs_error,
      labels: [job_name]
    )

    Gauge.dec(
      name: :step_flow_jobs_processing,
      labels: [job_name]
    )
  end

  def inc(:step_flow_jobs_completed, job_name) do
    Counter.inc(
      name: :step_flow_jobs_completed,
      labels: [job_name]
    )

    Gauge.dec(
      name: :step_flow_jobs_processing,
      labels: [job_name]
    )
  end
end
