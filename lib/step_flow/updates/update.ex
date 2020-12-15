defmodule StepFlow.Updates.Update do
  use Ecto.Schema
  import Ecto.Changeset
  alias StepFlow.Jobs.Job
  alias StepFlow.Updates.Update

  @moduledoc false

  schema "step_flow_updates" do
    field(:datetime, :utc_datetime)
    field(:docker_container_id, :string)
    field(:parameters, {:array, :map})
    belongs_to(:job, Job, foreign_key: :job_id)

    timestamps()
  end

  @doc false
  def changeset(%Update{} = update, attrs) do
    update
    |> cast(attrs, [:datetime, :docker_container_id, :job_id, :update])
    |> foreign_key_constraint(:job_id)
    |> validate_required([:datetime, :docker_container_id, :job_id, :update])
  end

  @doc """
  Returns the last updated update of a list of updates.
  """
  def get_last_update(update) when is_list(update) do
    update
    |> Enum.sort(fn state_1, state_2 ->
      state_1.updated_at < state_2.updated_at
    end)
    |> List.last()
  end

  def get_last_update(%Update{} = update), do: update
  def get_last_update(_update), do: nil
end
