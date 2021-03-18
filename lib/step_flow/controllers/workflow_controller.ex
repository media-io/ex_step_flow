defmodule StepFlow.WorkflowController do
  use StepFlow, :controller
  use BlueBird.Controller

  require Logger

  alias StepFlow.Configuration
  alias StepFlow.Controller.Helpers
  alias StepFlow.Metrics.WorkflowInstrumenter
  alias StepFlow.Repo
  alias StepFlow.Step
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow

  action_fallback(StepFlow.FallbackController)

  def index(%Plug.Conn{assigns: %{current_user: user}} = conn, params) do
    workflows =
      params
      |> Map.put("rights", user.rights)
      |> Workflows.list_workflows()

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("index.json", workflows: workflows)
  end

  def index(conn, _) do
    conn
    |> put_status(:forbidden)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Forbidden to view workflows."}
    )
  end

  def create_workflow(conn, workflow_params) do
    case Workflows.create_workflow(workflow_params) do
      {:ok, %Workflow{} = workflow} ->
        WorkflowInstrumenter.inc(:step_flow_workflows_created, workflow.identifier)
        Workflows.Status.define_workflow_status(workflow.id, :created_workflow)
        Step.start_next(workflow)

        StepFlow.Notification.send("new_workflow", %{workflow_id: workflow.id})

        conn
        |> put_status(:created)
        |> put_view(StepFlow.WorkflowView)
        |> render("created.json", workflow: workflow)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end

  def create(
        %Plug.Conn{assigns: %{current_user: user}} = conn,
        %{"workflow_identifier" => identifier} = workflow_params
      ) do
    case StepFlow.WorkflowDefinitions.get_workflow_definition(identifier) do
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(StepFlow.WorkflowDefinitionView)
        |> render("error.json",
          errors: %{reason: "Unable to locate workflow with this identifier"}
        )

      workflow_definition ->
        if Helpers.has_right(workflow_definition, user, "create") do
          workflow_description =
            workflow_definition
            |> Map.put(:reference, Map.get(workflow_params, "reference"))
            |> Map.put(
              :parameters,
              merge_parameters(
                StepFlow.Map.get_by_key_or_atom(workflow_definition, :parameters),
                Map.get(workflow_params, "parameters", %{})
              )
            )
            |> Map.put(
              :rights,
              workflow_definition
              |> Map.get(:rights)
              |> Enum.map(fn right -> Map.from_struct(right) end)
            )
            |> Map.from_struct()

          create_workflow(conn, workflow_description)
        else
          conn
          |> put_status(:forbidden)
          |> put_view(StepFlow.WorkflowDefinitionView)
          |> render("error.json",
            errors: %{reason: "Forbidden to create workflow with this identifier"}
          )
        end
    end
  end

  def create(conn, _workflow_params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Missing Workflow identifier parameter"}
    )
  end

  defp merge_parameters(parameters, request_parameters, result \\ [])
  defp merge_parameters([], _request_parameters, result), do: result

  defp merge_parameters([parameter | tail], request_parameters, result) do
    result =
      case Map.get(request_parameters, Map.get(parameter, "id")) do
        nil ->
          List.insert_at(result, -1, parameter)

        parameter_value ->
          List.insert_at(result, -1, Map.put(parameter, "value", parameter_value))
      end

    merge_parameters(tail, request_parameters, result)
  end

  def show(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    workflow =
      Workflows.get_workflow!(id)
      |> Repo.preload(:jobs)

    if Helpers.has_right(workflow, user, "view") do
      conn
      |> put_view(StepFlow.WorkflowView)
      |> render("show.json", workflow: workflow)
    else
      conn
      |> put_status(:forbidden)
      |> put_view(StepFlow.WorkflowDefinitionView)
      |> render("error.json",
        errors: %{reason: "Forbidden to view workflow with this identifier"}
      )
    end
  end

  def show(conn, _) do
    conn
    |> put_status(:forbidden)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Forbidden to show workflow with this identifier"}
    )
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

  def statistics(
        %Plug.Conn{assigns: %{current_user: user}} = conn,
        %{"identifiers" => identifiers} = params
      )
      when is_list(identifiers) or identifiers == "all" do
    start_date =
      params
      |> Map.get(
        "start_date",
        NaiveDateTime.utc_now() |> NaiveDateTime.add(-86_400, :second) |> NaiveDateTime.to_string()
      )
      |> NaiveDateTime.from_iso8601!()
      |> NaiveDateTime.truncate(:second)

    end_date =
      params
      |> Map.get(
        "end_date",
        NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
      )
      |> NaiveDateTime.from_iso8601!()
      |> NaiveDateTime.truncate(:second)

    time_interval =
      params
      |> Map.get("time_interval", define_time_interval(start_date, end_date))
      |> String.to_integer()
      |> Kernel.max(1)

    workflows_status =
      Workflows.Status.list_workflows_status(start_date, end_date, identifiers, user.rights)

    conn
    |> put_view(StepFlow.WorkflowView)
    |> render("statistics.json", %{
      workflows_status: workflows_status,
      time_interval: time_interval,
      end_date: end_date
    })
  end

  def statistics(conn, params) do
    Logger.error("#{inspect(params)}")

    conn
    |> put_status(:forbidden)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Requires 2 parameters: start_date and identifiers."}
    )
  end

  defp define_time_interval(start_date, end_date) do
    with number_bins <- Configuration.get_var_value(StepFlow.Workflows, :number_bins, 60) do
      NaiveDateTime.diff(end_date, start_date, :second)
      |> Kernel.div(number_bins)
      |> Integer.to_string()
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Forbidden to update workflow with this identifier"}
    )
  end

  def delete(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    workflow = Workflows.get_workflow!(id)

    if Helpers.has_right(workflow, user, "delete") do
      with {:ok, %Workflow{}} <- Workflows.delete_workflow(workflow) do
        send_resp(conn, :no_content, "")
      end
    else
      conn
      |> put_status(:forbidden)
      |> put_view(StepFlow.WorkflowDefinitionView)
      |> render("error.json",
        errors: %{reason: "Forbidden to update workflow with this identifier"}
      )
    end
  end

  def delete(conn, _) do
    conn
    |> put_status(:forbidden)
    |> put_view(StepFlow.WorkflowDefinitionView)
    |> render("error.json",
      errors: %{reason: "Forbidden to delete workflow with this identifier"}
    )
  end
end
