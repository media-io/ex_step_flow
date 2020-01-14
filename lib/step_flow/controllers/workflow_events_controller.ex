defmodule StepFlow.WorkflowEventsController do
  use StepFlow, :controller
  require Logger

  alias StepFlow.Amqp.CommonEmitter
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Workflows
  alias StepFlow.Jobs.Status

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
        job = Jobs.get_job!(job_id)

        Status.set_job_status(job_id, Status.status_enum_label(:retrying))

        params = %{
          job_id: job.id,
          parameters: job.parameters
        }

        case CommonEmitter.publish_json(job.name, job.step_id, params) do
          :ok ->
            conn
            |> put_status(:ok)
            |> json(%{status: "ok"})

          _ ->
            conn
            |> put_status(:ok)
            |> json(%{status: "error", message: "unable to publish message"})
        end

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

  defp skip_remaining_steps([], _workflow), do: nil

  defp skip_remaining_steps([step | steps], workflow) do
    case Status.status_enum_from_label(step.status) do
      :queued -> StepFlow.Step.skip_step(workflow, step)
      :processing -> StepFlow.Step.skip_step_jobs(workflow, step)
      _ -> nil
    end

    skip_remaining_steps(steps, workflow)
  end
end
