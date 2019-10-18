defmodule StepFlow.Jobs.Status do
  use Ecto.Schema
  import Ecto.Changeset

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
end
