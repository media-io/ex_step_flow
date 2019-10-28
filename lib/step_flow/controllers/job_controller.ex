defmodule StepFlow.JobController do
  use StepFlow, :controller

  # import ExBackendWeb.Authorize

  alias StepFlow.Jobs
  # alias StepFlow.Jobs.Job
  # alias ExBackend.Amqp.CommonEmitter

  action_fallback(ExBackendWeb.FallbackController)

  # the following plugs are defined in the controllers/authorize.ex file
  # plug(:user_check when action in [:index, :show, :update, :delete])
  # plug(:right_technician_or_ftvstudio_check when action in [:index, :show, :update, :delete])

  def index(conn, params) do
    jobs = Jobs.list_jobs(params)

    conn
    |> put_view(StepFlow.JobView)
    |> render("index.json", jobs: jobs)
  end
end
