defmodule StepFlow.Workflows.Status do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EctoEnum

  alias StepFlow.Jobs
  alias StepFlow.Progressions.Progression
  alias StepFlow.Repo
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow
  require Logger

  @moduledoc false

  defenum(StateEnum, ["pending", "skipped", "processing", "retrying", "error", "completed"])

  def state_enum_label(value) do
    case value do
      value when value in [0, :pending] -> "pending"
      value when value in [1, :skipped] -> "skipped"
      value when value in [2, :processing] -> "processing"
      value when value in [3, :retrying] -> "retrying"
      value when value in [4, :error] -> "error"
      value when value in [5, :completed] -> "completed"
      _ -> "unknown"
    end
  end

  schema "step_flow_workflow_status" do
    field(:state, StepFlow.Workflows.Status.StateEnum)
    belongs_to(:status, Jobs.Status, foreign_key: :job_status_id, defaults: nil)
    belongs_to(:workflow, Workflow, foreign_key: :workflow_id)

    timestamps()
  end

  @doc false
  def changeset(%Workflows.Status{} = status, attrs) do
    status
    |> cast(attrs, [:workflow_id, :state, :job_status_id])
    |> foreign_key_constraint(:workflow_id)
    |> validate_required([:state, :workflow_id])
  end

  @doc """
  Define the workflow status given events. It also tracks completed, retrying
  and error job status of a workflow.

  Returns `{:ok, workflow_status}` if the event is correct, nil otherwise

  ## Examples

      iex> define_workflow_status(1, :completed_workflow)
      {:ok, %Workflows.Status{state: :completed, workflow_id: 1, job_id: nil, id: 1}}

      iex> define_workflow_status(1, :incorrect_event)
      nil

  """
  def define_workflow_status(workflow_id, event, payload \\ %{})

  def define_workflow_status(workflow_id, :created_workflow, _payload) do
    set_workflow_status(workflow_id, :pending)
  end

  def define_workflow_status(workflow_id, :job_progression, %Progression{progression: 0}) do
    last_status = get_last_workflow_status(workflow_id)

    if last_status.state == :pending do
      set_workflow_status(workflow_id, :processing)
    else
      Logger.warn(
        "Can't set workflow #{workflow_id} to :processing because current state is #{
          last_status.state
        }."
      )

      {:ok, last_status}
    end
  end

  def define_workflow_status(workflow_id, :job_completed, %Jobs.Status{
        id: job_status_id,
        job_id: job_id
      }) do
    jobs_status_not_completed =
      get_last_jobs_status(workflow_id)
      |> Enum.filter(fn s -> s.state in [:error, :retrying] and s.job_id != job_id end)
      |> length()

    if jobs_status_not_completed == 0 do
      set_workflow_status(workflow_id, :pending, job_status_id)
    else
      last_status = get_last_workflow_status(workflow_id)
      set_workflow_status(workflow_id, last_status.state, job_status_id)
    end
  end

  def define_workflow_status(workflow_id, :job_retrying, %Jobs.Status{
        id: job_status_id,
        job_id: job_id
      }) do
    jobs_status_in_error =
      get_last_jobs_status(workflow_id)
      |> Enum.filter(fn s -> s.state == :error and s.job_id != job_id end)
      |> length()

    if jobs_status_in_error == 0 do
      set_workflow_status(workflow_id, :processing, job_status_id)
    else
      set_workflow_status(workflow_id, :error, job_status_id)
    end
  end

  def define_workflow_status(workflow_id, :completed_workflow, _payload) do
    last_status = get_last_workflow_status(workflow_id)

    if last_status != nil do
      Logger.info("Complete wokflow #{workflow_id} from state #{last_status.state}.")
    end

    set_workflow_status(workflow_id, :completed)
  end

  def define_workflow_status(workflow_id, event, %Jobs.Status{id: job_status_id})
      when event in [:job_error, :queue_not_found] do
    set_workflow_status(workflow_id, :error, job_status_id)
  end

  def define_workflow_status(_workflow_id, _event, _payload), do: nil

  def set_workflow_status(workflow_id, status, job_status_id \\ nil) do
    %Workflows.Status{}
    |> Workflows.Status.changeset(%{
      workflow_id: workflow_id,
      state: status,
      job_status_id: job_status_id
    })
    |> Repo.insert()
  end

  @doc """
  Returns the last updated status of a workflow per job_id.
  """
  def get_last_jobs_status(workflow_id) when is_number(workflow_id) do
    query =
      from(
        job_status in Jobs.Status,
        inner_join:
          workflow_status in subquery(
            from(
              workflow_status in Workflows.Status,
              where: workflow_status.workflow_id == ^workflow_id
            )
          ),
        on: workflow_status.job_status_id == job_status.id,
        order_by: [
          desc: field(workflow_status, :inserted_at),
          desc: field(job_status, :id),
          asc: field(job_status, :job_id)
        ],
        distinct: [asc: field(job_status, :job_id)]
      )

    Repo.all(query)
  end

  @doc """
  Returns the last updated status of a workflow.
  """
  def get_last_workflow_status(workflow_id) when is_number(workflow_id) do
    query =
      from(
        workflow_status in Workflows.Status,
        where: workflow_status.workflow_id == ^workflow_id,
        order_by: [desc: :updated_at, desc: :id],
        limit: 1
      )

    Repo.one(query)
  end

  def get_last_workflow_status(_workflow_id), do: nil

  @doc """
  """
  def list_workflows_status(start_date, end_date, identifiers, user_rights) do
    query =
      if identifiers == "all" do
        from(
          workflow in Workflow,
          join: rights in assoc(workflow, :rights),
          where: rights.action == "view",
          where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights)
        )
      else
        from(
          workflow in Workflow,
          where: workflow.identifier in ^identifiers,
          join: rights in assoc(workflow, :rights),
          where: rights.action == "view",
          where: fragment("?::varchar[] && ?::varchar[]", rights.groups, ^user_rights)
        )
      end

    query =
      from(
        workflows_status in Workflows.Status,
        inner_join: workflow in subquery(query),
        on: workflows_status.workflow_id == workflow.id,
        where:
          fragment("?::timestamp", workflows_status.inserted_at) >= ^start_date and
            fragment("?::timestamp", workflows_status.inserted_at) <= ^end_date and
            workflows_status.state in [:completed, :error, :processing]
      )

    Repo.all(query)
  end
end
