defmodule StepFlow.Workflows.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  alias StepFlow.Artifacts.Artifact
  alias StepFlow.Jobs.Job
  alias StepFlow.Workflows.Workflow

  @moduledoc false

  schema "workflow" do
    field(:identifier, :string)
    field(:version_major, :integer)
    field(:version_minor, :integer)
    field(:version_micro, :integer)
    field(:tags, {:array, :string}, default: [])
    field(:reference, :string)
    field(:flow, :map)
    field(:parameters, {:array, :map}, default: [])
    has_many(:jobs, Job, on_delete: :delete_all)
    has_many(:artifacts, Artifact, on_delete: :delete_all)

    timestamps()
  end

  @doc false
  def changeset(%Workflow{} = workflow, attrs) do
    workflow
    |> cast(attrs, [
      :identifier,
      :version_major,
      :version_minor,
      :version_micro,
      :tags,
      :parameters,
      :reference,
      :flow
    ])
    |> validate_required([
      :identifier,
      :version_major,
      :version_minor,
      :version_micro,
      :reference,
      :flow
    ])
  end
end
