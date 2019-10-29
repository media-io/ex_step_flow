defmodule StepFlow.JobController do
  use StepFlow, :controller

  alias StepFlow.Jobs

  action_fallback(ExBackendWeb.FallbackController)

  def index(conn, params) do
    jobs = Jobs.list_jobs(params)

    conn
    |> put_view(StepFlow.JobView)
    |> render("index.json", jobs: jobs)
  end
end
