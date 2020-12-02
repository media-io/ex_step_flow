defmodule StepFlow.Workflows.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  alias StepFlow.Artifacts.Artifact
  alias StepFlow.Jobs.Job
  alias StepFlow.Rights.Right
  alias StepFlow.Workflows.Workflow

  @moduledoc false

  schema "step_flow_workflow" do
    field(:schema_version, :string)
    field(:identifier, :string)
    field(:version_major, :integer)
    field(:version_minor, :integer)
    field(:version_micro, :integer)
    field(:tags, {:array, :string}, default: [])
    field(:is_live, :boolean, default: false)
    field(:reference, :string)
    field(:steps, {:array, :map}, default: [])
    field(:parameters, {:array, :map}, default: [])
    has_many(:jobs, Job, on_delete: :delete_all)
    has_many(:artifacts, Artifact, on_delete: :delete_all)

    many_to_many(:rights, Right,
      join_through: "step_flow_workflow_right",
      on_delete: :delete_all,
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(%Workflow{} = workflow, attrs) do
    workflow
    |> cast(attrs, [
      :schema_version,
      :identifier,
      :version_major,
      :version_minor,
      :version_micro,
      :tags,
      :is_live,
      :parameters,
      :reference,
      :steps
    ])
    |> cast_assoc(:rights, required: true)
    |> validate_required([
      :schema_version,
      :identifier,
      :version_major,
      :version_minor,
      :version_micro,
      :reference,
      :steps
    ])
  end
end
