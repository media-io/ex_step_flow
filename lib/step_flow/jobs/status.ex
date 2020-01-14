defmodule StepFlow.Jobs.Status do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  alias StepFlow.Jobs.Job
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo

  @moduledoc false

  schema "step_flow_status" do
    field(:state, :string)
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

  defenum(StateEnum, queued: 0, skipped: 1, processing: 2, retrying: 3, error: 4, completed: 5)

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

  def state_enum_from_label(label) do
    case label do
      "queued" -> :queued
      "skipped" -> :skipped
      "processing" -> :processing
      "retrying" -> :retrying
      "error" -> :error
      "completed" -> :completed
      _ -> nil
    end
  end

  @doc """
  Returns the last updated status of a list of status.
  """
  def get_last_status(status) when is_list(status) do
    status
    |> Enum.sort(fn s1, s2 -> s1.updated_at < s2.updated_at end)
    |> List.last()
  end

  def get_last_status(%Status{} = status), do: status
  def get_last_status(_status), do: nil
end
