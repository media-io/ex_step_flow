defmodule StepFlow.WorkflowEventsController do
  use StepFlow, :controller
  require Logger

  alias StepFlow.{
    Amqp.CommonEmitter,
    Jobs,
    Jobs.Status,
    Notifications.Notification,
    Step.Helpers,
    Step.Launch,
    Workflows
  }

  action_fallback(StepFlow.FallbackController)

  def handle(conn, %{"id" => id} = params) do
    workflow = Workflows.get_workflow!(id)

    case params do
      %{"event" => "abort"} ->
        workflow.steps
        |> skip_remaining_steps(workflow)

        topic = "update_workflow_" <> Integer.to_string(workflow.id)
        StepFlow.Notification.send(topic, %{workflow_id: workflow.id})

        conn
        |> put_status(:ok)
        |> json(%{status: "ok"})

      %{"event" => "retry", "job_id" => job_id} ->
        Logger.warn("retry job #{job_id}")

        job = Jobs.get_job_with_status!(job_id)

        last_status = Status.get_last_status(job.status)

        internal_handle(conn, workflow, job, job.name, last_status.state)

      %{"event" => "delete"} ->
        for job <- workflow.jobs do
          Jobs.delete_job(job)
        end

        Workflows.delete_workflow(workflow)
        StepFlow.Notification.send("delete_workflow", %{workflow_id: workflow.id})

        conn
        |> put_status(:ok)
        |> json(%{status: "ok"})

      _ ->
        send_resp(conn, 422, "event is not supported")
    end
  end

  defp internal_handle(conn, _workflow, job, "job_notification", :error) do
    Status.set_job_status(job.id, :retrying)

    %{step: step, workflow: workflow} = Workflows.get_step_definition(job)
    dates = Helpers.get_dates()
    source_paths = Launch.get_source_paths(workflow, step, dates)

    step_name = StepFlow.Map.get_by_key_or_atom(step, :name)
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    {:ok, _} =
      Notification.process(workflow, dates, step_name, step, step_id, source_paths)

    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  defp internal_handle(conn, workflow, job, _job_name, :error) do
    Status.set_job_status(job.id, :retrying)
    params = %{
      job_id: job.id,
      parameters: job.parameters
    }

    case CommonEmitter.publish_json(job.name, job.step_id, params) do
      :ok ->
        StepFlow.Notification.send("retry_job", %{workflow_id: workflow.id, body: params})

        conn
        |> put_status(:ok)
        |> json(%{status: "ok"})

      _ ->
        conn
        |> put_status(:ok)
        |> json(%{status: "error", message: "unable to publish message"})
    end
  end

  defp internal_handle(conn, _workflow, _job, _job_name, _last_status_state) do
    send_resp(conn, :forbidden, "illegal operation")
  end

  defp skip_remaining_steps([], _workflow), do: nil

  defp skip_remaining_steps([step | steps], workflow) do
    case step.status do
      :queued -> StepFlow.Step.skip_step(workflow, step)
      :processing -> StepFlow.Step.skip_step_jobs(workflow, step)
      _ -> nil
    end

    skip_remaining_steps(steps, workflow)
  end
end
