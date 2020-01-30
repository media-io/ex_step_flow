defmodule StepFlow.Progressions.Progression do
  use Ecto.Schema
  import Ecto.Changeset
  alias StepFlow.Jobs.Job
  alias StepFlow.Progressions.Progression

  @moduledoc false

  schema "step_flow_progressions" do
    field(:datetime, :utc_datetime)
    field(:docker_container_id, :string)
    field(:progression, :integer)
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps()
  end

  @doc false
  def changeset(%Progression{} = progression, attrs) do
    progression
    |> cast(attrs, [:datetime, :docker_container_id, :job_id, :progression])
    |> foreign_key_constraint(:job_id)
    |> validate_required([:datetime, :docker_container_id, :job_id, :progression])
  end

  @doc """
  Returns the last updated progression of a list of progression.
  """
  def get_last_progression(progression) when is_list(progression) do
    progression
    |> Enum.sort(fn state_1, state_2 ->
      state_1.updated_at < state_2.updated_at
    end)
    |> List.last()
  end
  def get_last_progression(%Progression{} = progression), do: progression
  def get_last_progression(_progression), do: nil
end
