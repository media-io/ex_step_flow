defmodule StepFlow.Metrics.JobInstrumenterTest do
  use ExUnit.Case
  use Plug.Test

  alias Prometheus.Metric
  alias StepFlow.Metrics.JobInstrumenter

  setup do
    Metric.Counter.reset(
      name: :step_flow_jobs_created,
      labels: ["job_test"]
    )

    Metric.Counter.reset(
      name: :step_flow_jobs_error,
      labels: ["job_test"]
    )

    Metric.Counter.reset(
      name: :step_flow_jobs_completed,
      labels: ["job_test"]
    )

    Metric.Gauge.reset(
      name: :step_flow_jobs_processing,
      labels: ["job_test"]
    )

    :ok
  end

  test "inc :step_flow_jobs_created" do
    JobInstrumenter.inc(:step_flow_jobs_created, "job_test")

    assert Metric.Counter.value(
             name: :step_flow_jobs_created,
             labels: ["job_test"]
           ) == 1

    assert Metric.Gauge.value(
             name: :step_flow_jobs_processing,
             labels: ["job_test"]
           ) == 1
  end

  test "inc :step_flow_jobs_error" do
    JobInstrumenter.inc(:step_flow_jobs_error, "job_test")

    assert Metric.Counter.value(
             name: :step_flow_jobs_error,
             labels: ["job_test"]
           ) == 1

    assert Metric.Gauge.value(
             name: :step_flow_jobs_processing,
             labels: ["job_test"]
           ) == -1
  end

  test "inc :step_flow_jobs_completed" do
    JobInstrumenter.inc(:step_flow_jobs_completed, "job_test")

    assert Metric.Counter.value(
             name: :step_flow_jobs_completed,
             labels: ["job_test"]
           ) == 1

    assert Metric.Gauge.value(
             name: :step_flow_jobs_processing,
             labels: ["job_test"]
           ) == -1
  end
end
