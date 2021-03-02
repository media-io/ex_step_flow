defmodule StepFlow.Workflows.Status do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EctoEnum

  alias StepFlow.Jobs
  alias StepFlow.Repo
  alias StepFlow.Workflows
  alias StepFlow.Workflows.Workflow
  require Logger

  @moduledoc false

  defenum(StateEnum, ["queued", "skipped", "processing", "retrying", "error", "completed"])

  def state_enum_label(value) do
    case value do
      value when value in [0, :queued] -> "queued"
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

  def define_workflow_status(workflow_id, state, payload \\ %{})

  def define_workflow_status(workflow_id, :error, %{id: job_status_id}) do
    set_workflow_status(workflow_id, :error, job_status_id)
  end

  def define_workflow_status(workflow_id, :retrying, %{id: job_status_id, job_id: job_id}) do
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

  def define_workflow_status(workflow_id, :processing, %{progression: 0}) do
    last_status = get_last_workflow_status(workflow_id)
    if last_status.state == :queued do
      set_workflow_status(workflow_id, :processing)
    else
      {:ok, last_status}
    end
  end

  def define_workflow_status(workflow_id, :queud, %{progression: 0}) do
    last_status = get_last_workflow_status(workflow_id)
    if last_status == nil do
      set_workflow_status(workflow_id, :queued)
    else
      {:ok, last_status}
    end
  end

  def define_workflow_status(_workflow_id, _state, _payload), do: nil

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
        order_by: [desc: field(workflow_status, :inserted_at), asc: field(job_status, :job_id)],
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
        order_by: [desc: :updated_at],
        limit: 1
      )

    Repo.one(query)
  end

  def get_last_workflow_status(_workflow_id), do: nil
end
