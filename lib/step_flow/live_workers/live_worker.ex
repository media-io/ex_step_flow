defmodule StepFlow.LiveWorkers.LiveWorker do
  use Ecto.Schema
  import Ecto.Changeset
  alias StepFlow.Jobs.Job
  alias StepFlow.LiveWorkers.LiveWorker

  @moduledoc false

  schema "step_flow_live_workers" do
    field(:ips, {:array, :string}, default: [])
    field(:ports, {:array, :integer}, default: [])
    field(:instance_id, :string, default: "")
    field(:direct_messaging_queue_name, :string)
    field(:creation_date, :utc_datetime)
    field(:termination_date, :utc_datetime)
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps()
  end

  @doc false
  def changeset(%LiveWorker{} = live_worker, attrs) do
    live_worker
    |> cast(attrs, [
      :ips,
      :ports,
      :job_id,
      :instance_id,
      :direct_messaging_queue_name,
      :creation_date,
      :termination_date
    ])
    |> foreign_key_constraint(:job_id)
    |> validate_required([:job_id, :direct_messaging_queue_name])
  end
end
