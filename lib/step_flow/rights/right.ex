defmodule StepFlow.Rights.Right do
  @moduledoc """
  The WorkflowDefinition context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  require Logger
  alias StepFlow.Rights.Right

  schema "step_flow_right" do
    field(:action, :string)
    field(:groups, {:array, :string}, default: [])

    timestamps()
  end

  @doc false
  def changeset(%Right{} = right, attrs) do
    right
    |> cast(attrs, [
      :action,
      :groups
    ])
  end
end
