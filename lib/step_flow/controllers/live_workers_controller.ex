defmodule StepFlow.LiveWorkersController do
  use StepFlow, :controller

  alias StepFlow.LiveWorkers
  alias StepFlow.LiveWorkers.LiveWorker

  action_fallback(StepFlow.FallbackController)

  def index(conn, params) do
    live_workers = LiveWorkers.list_live_workers(params)

    conn
    |> put_view(StepFlow.LiveWorkersView)
    |> render("index.json", live_workers: live_workers)
  end
end
