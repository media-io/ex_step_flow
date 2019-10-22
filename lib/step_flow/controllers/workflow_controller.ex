defmodule StepFlow.WorkflowController do
  use Phoenix.Controller
  use BlueBird.Controller

  # import StepFlow.Authorize
  # import Application.fetch_env!(:step_flow, :authorize)
  require Logger

  alias StepFlow.Repo
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow
  alias StepFlow.WorkflowStep

  action_fallback(StepFlow.FallbackController)

  # use StepFlow.AuthenticationBehaviour

  # @callback extension(arg :: any) :: any
  # the following plugs are defined in the controllers/authorize.ex file
  # plug(:user_check when action in [:index, :create, :create_specific, :show, :update, :delete])
  # plug(Application.fetch_env!(:step_flow, :user_check) when action in
    # [:index, :create, :create_specific, :show, :update, :delete])

  # plug(
  #   :right_technician_or_ftvstudio_check
  #   when action in [:index, :show, :update, :delete]
  # )

  def index(conn, params) do
    workflows = Workflows.list_workflows(params)

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("index.json", workflows: workflows)
  end

  def create(conn, workflow_params) do
    case Workflows.create_workflow(workflow_params) do
      {:ok, %Workflow{} = workflow} ->
        WorkflowStep.start_next_step(workflow)

        # StepFlow.Endpoint.broadcast!("notifications:all", "new_workflow", %{
        #   body: %{workflow_id: workflow.id}
        # })

        conn
        |> put_status(:created)
        |> put_view(StepFlow.WorkflowView)
        |> render("show.json", workflow: workflow)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    workflow =
      Workflows.get_workflow!(id)
      |> Repo.preload(:jobs)

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("show.json", workflow: workflow)
  end

  def get(conn, %{"identifier" => workflow_identifier} = _params) do
    workflow =
      case workflow_identifier do
        _ -> %{}
      end

    conn
    |> json(workflow)
  end

  def get(conn, _params) do
    conn
    |> json(%{})
  end

  def statistics(conn, params) do
    scale = Map.get(params, "scale", "hour")
    stats = Workflows.get_workflow_history(%{scale: scale})

    conn
    |> json(%{
      data: stats
    })
  end

  def update(conn, %{"id" => id, "workflow" => workflow_params}) do
    workflow = Workflows.get_workflow!(id)

    with {:ok, %Workflow{} = workflow} <- Workflows.update_workflow(workflow, workflow_params) do
      conn
      |> put_view(StepFlow.WorkflowView)
      |> render("show.json", workflow: workflow)
    end
  end

  def delete(conn, %{"id" => id}) do
    workflow = Workflows.get_workflow!(id)

    with {:ok, %Workflow{}} <- Workflows.delete_workflow(workflow) do
      send_resp(conn, :no_content, "")
    end
  end
end
