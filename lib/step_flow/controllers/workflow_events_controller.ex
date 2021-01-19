defmodule StepFlow.WorkflowEventsController do
  use StepFlow, :controller
  require Logger

  import StepFlow.Controller.Helpers

  alias StepFlow.{
    Amqp.CommonEmitter,
    Jobs,
    Jobs.Status,
    Notifications.Notification,
    Step.Helpers,
    Step.Launch,
    Updates,
    Workflows
  }

  action_fallback(StepFlow.FallbackController)

  def handle(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id} = params) do
    workflow = Workflows.get_workflow!(id)

    case params do
      %{"event" => "abort"} ->
        abort(conn, workflow, user)

      %{"event" => "update", "job_id" => job_id, "parameters" => parameters} ->
        update(conn, workflow, user, job_id, parameters)

      %{"event" => "retry", "job_id" => job_id} ->
        retry(conn, workflow, user, job_id)

      %{"event" => "stop"} ->
        stop(conn, workflow, user)

      %{"event" => "delete"} ->
        delete(conn, workflow, user)

      _ ->
        send_resp(conn, 422, "event is not supported")
    end
  end

  def handle(conn, _) do
    conn
    |> put_status(:forbidden)
    |> json(%{status: "error", message: "Forbidden to handle workflow with this identifier"})
  end

  defp internal_handle(conn, _workflow, job, "job_notification", :error) do
    Status.set_job_status(job.id, :retrying)

    %{step: step, workflow: workflow} = Workflows.get_step_definition(job)
    dates = Helpers.get_dates()
    source_paths = Launch.get_source_paths(workflow, step, dates)

    step_name = StepFlow.Map.get_by_key_or_atom(step, :name)
    step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

    {:ok, _} = Notification.process(workflow, dates, step_name, step, step_id, source_paths)

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

  defp stop_all_jobs([]), do: nil

  defp stop_all_jobs([job | jobs]) do
    StepFlow.Step.Live.stop_job(job)

    stop_all_jobs(jobs)
  end

  defp update(conn, workflow, user, job_id, parameters) do
    if has_right(workflow, user, "update") do
      Logger.warn("update job #{job_id}")

      job = Jobs.get_job_with_status!(job_id)

      if job.is_updatable do
        Updates.update_parameters(job, parameters)

        conn
        |> put_status(:ok)
        |> json(%{status: "ok"})
      else
        Logger.error("Job #{job_id} cannot be updated !")

        conn
        |> put_status(:error)
        |> json(%{status: "error", message: "Forbidden to update this job"})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{status: "error", message: "Forbidden to update this workflow"})
    end
  end

  defp abort(conn, workflow, user) do
    if has_right(workflow, user, "abort") do
      workflow.steps
      |> skip_remaining_steps(workflow)

      topic = "update_workflow_" <> Integer.to_string(workflow.id)
      StepFlow.Notification.send(topic, %{workflow_id: workflow.id})

      conn
      |> put_status(:ok)
      |> json(%{status: "ok"})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{status: "error", message: "Forbidden to abort this workflow"})
    end
  end

  defp retry(conn, workflow, user, job_id) do
    if has_right(workflow, user, "retry") do
      Logger.warn("retry job #{job_id}")

      job = Jobs.get_job_with_status!(job_id)

      last_status = Status.get_last_status(job.status)

      internal_handle(conn, workflow, job, job.name, last_status.state)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{status: "error", message: "Forbidden to retry this workflow"})
    end
  end

  defp stop(conn, workflow, user) do
    if has_right(workflow, user, "stop") do
      workflow_jobs = Repo.preload(workflow, [:jobs]).jobs

      workflow_jobs
      |> stop_all_jobs()

      topic = "update_workflow_" <> Integer.to_string(workflow.id)
      StepFlow.Notification.send(topic, %{workflow_id: workflow.id})

      conn
      |> put_status(:ok)
      |> json(%{status: "ok"})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{status: "error", message: "Forbidden to stop this workflow"})
    end
  end

  defp delete(conn, workflow, user) do
    if has_right(workflow, user, "delete") do
      for job <- workflow.jobs do
        Jobs.delete_job(job)
      end

      Workflows.delete_workflow(workflow)
      StepFlow.Notification.send("delete_workflow", %{workflow_id: workflow.id})

      conn
      |> put_status(:ok)
      |> json(%{status: "ok"})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{status: "error", message: "Forbidden to delete this workflow"})
    end
  end
end
