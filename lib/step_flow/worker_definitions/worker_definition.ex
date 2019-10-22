defmodule StepFlow.WorkerDefinitions.WorkerDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  alias StepFlow.WorkerDefinitions.WorkerDefinition

  @moduledoc false
  schema "step_flow_worker_definitions" do
    field(:queue_name, :string)
    field(:label, :string)
    field(:version, :string)
    field(:git_version, :string)
    field(:short_description, :string)
    field(:description, :string)
    field(:parameters, {:array, :map}, default: [])
    
    timestamps()
  end

  @doc false
  def changeset(%WorkerDefinition{} = workflow, attrs) do
    workflow
    |> cast(attrs, [
      :queue_name,
      :label,
      :version,
      :git_version,
      :short_description,
      :description,
      :parameters
    ])
    |> validate_required([
      :queue_name,
      :label,
      :version,
      :git_version,
      :short_description,
      :description
    ])
  end
end
