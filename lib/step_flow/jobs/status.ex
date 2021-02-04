defmodule StepFlow.Jobs.Status do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  alias StepFlow.Jobs.Job
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo

  @moduledoc false

  defenum(StateEnum, [
    "queued",
    "skipped",
    "processing",
    "retrying",
    "error",
    "completed",
    "ready_to_init",
    "ready_to_start",
    "update",
    "stopped"
  ])

  defp state_map_lookup(value) do
    state_map = %{
      0 => :queued,
      1 => :skipped,
      2 => :processing,
      3 => :retrying,
      4 => :error,
      5 => :completed,
      6 => :ready_to_init,
      7 => :ready_to_start,
      8 => :update,
      9 => :stopped
    }

    if is_number(value) do
      state_map[value]
    else
      case Map.values(state_map) |> Enum.member?(value) do
        true -> value
        _ -> nil
      end
    end
  end

  def state_enum_label(value) do
    to_atom(value)
    |> Atom.to_string()
  end

  defp to_atom(value) do
    case state_map_lookup(value) do
      nil -> :unknown
      value -> value
    end
  end

  schema "step_flow_status" do
    field(:state, StepFlow.Jobs.Status.StateEnum)
    field(:description, :map, default: %{})
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps()
  end

  @doc false
  def changeset(%Status{} = job, attrs) do
    job
    |> cast(attrs, [:state, :job_id, :description])
    |> foreign_key_constraint(:job_id)
    |> validate_required([:state, :job_id])
  end

  def set_job_status(job_id, status, description \\ %{}) do
    %Status{}
    |> Status.changeset(%{job_id: job_id, state: status, description: description})
    |> Repo.insert()
  end

  @doc """
  Returns the last updated status of a list of status.
  """
  def get_last_status(status) when is_list(status) do
    status
    |> Enum.sort(fn state_1, state_2 ->
      state_1.updated_at < state_2.updated_at
    end)
    |> List.last()
  end

  def get_last_status(%Status{} = status), do: status
  def get_last_status(_status), do: nil

  @doc """
  Returns action linked to status
  """
  def get_action(status) do
    case status.state do
      :queued -> "create"
      :ready_to_init -> "init_process"
      :ready_to_start -> "start_process"
      :update -> "update_process"
      :stopped -> "delete"
      _ -> "none"
    end
  end

  @doc """
  Returns action linked to status as parameter
  """
  def get_action_parameter(status) do
    action = get_action(status)
    [%{"id" => "action", "type" => "string", "value" => action}]
  end
end
