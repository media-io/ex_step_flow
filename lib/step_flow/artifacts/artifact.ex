defmodule StepFlow.Artifacts.Artifact do
  use Ecto.Schema
  import Ecto.Changeset
  alias StepFlow.Artifacts.Artifact
  alias StepFlow.Workflows.Workflow

  @moduledoc false

  schema "step_flow_artifacts" do
    field(:resources, :map)
    belongs_to(:workflow, Workflow, foreign_key: :workflow_id)

    timestamps()
  end

  @doc false
  def changeset(%Artifact{} = artifact, attrs) do
    artifact
    |> cast(attrs, [:resources, :workflow_id])
    |> foreign_key_constraint(:workflow_id)
    |> validate_required([:resources, :workflow_id])
  end
end
