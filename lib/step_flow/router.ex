defmodule StepFlow.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  get("/", do: send_resp(conn, 200, "Welcome to Step Flow"))

  post "/workflows" do
    StepFlow.WorkflowController.create(conn, conn.body_params)
  end

  get "/workflows" do
    StepFlow.WorkflowController.index(conn, conn.body_params)
  end

  get "/workflows/statistics" do
    StepFlow.WorkflowController.statistics(conn, conn.body_params)
  end

  get "/workflows/:identifier" do
    StepFlow.WorkflowController.get(conn, conn.body_params)
  end

  # post "/workflow/:identifier" do
  #   StepFlow.WorkflowController.create_specific(conn, conn.body_params)
  # end

  # resources("/workflows", WorkflowController, except: [:new, :edit]) do
  #   post("/events", WorkflowEventsController, :handle)
  # end

  match(_, do: send_resp(conn, 404, "Not found"))
end
