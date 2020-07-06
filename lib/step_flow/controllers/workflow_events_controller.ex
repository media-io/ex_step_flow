defmodule StepFlow.WorkflowEventsController do
  use StepFlow, :controller
  require Logger

  alias StepFlow.{
    Amqp.CommonEmitter,
    Jobs,
    Jobs.Status,
    Notifications.Notification,
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

        if last_status.state == :error do
          Status.set_job_status(job_id, :retrying)

          if job.name == "job_notification" do
            %{step: step, workflow: workflow} = Workflows.get_step_definition(job)
            dates = StepFlow.Step.Helpers.get_dates()
            source_paths = StepFlow.Step.Launch.get_source_paths(workflow, step, dates)

            step_name = StepFlow.Map.get_by_key_or_atom(step, :name)
            step_id = StepFlow.Map.get_by_key_or_atom(step, :id)

            {:ok, _} =
              Notification.process(workflow, dates, step_name, step, step_id, source_paths)

            conn
            |> put_status(:ok)
            |> json(%{status: "ok"})
          else
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
        else
          send_resp(conn, :forbidden, "illegal operation")
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
    case step.status do
      :queued -> StepFlow.Step.skip_step(workflow, step)
      :processing -> StepFlow.Step.skip_step_jobs(workflow, step)
      _ -> nil
    end

    skip_remaining_steps(steps, workflow)
  end
end
