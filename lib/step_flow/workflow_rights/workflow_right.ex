defmodule StepFlow.WorkflowRights.WorkflowRight do
  @moduledoc """
  The WorkflowDefinition context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  require Logger
  alias StepFlow.Repo
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  alias StepFlow.WorkflowRights.WorkflowRight

  schema "step_flow_workflow_rights" do
    field(:right, :string)
    field(:group, :string)
    belongs_to(:workflow_definition, WorkflowDefinition, foreign_key: :workflow_definition_id)

    timestamps()
  end

  @doc false
  def changeset(%WorkflowRight{} = right, attrs) do
    right
    |> cast(attrs, [
      :right,
      :group,
      :workflow_definition_id
    ])
    |> foreign_key_constraint(:workflow_definition_id)
    |> validate_required([
      :right,
      :group,
      :workflow_definition_id
    ])
  end

  def load_rights_in_database(rights, workflow_definition_id) do
    rights
    |> Enum.each(fn {right, groups} ->
      groups
      |> Enum.each(fn group ->
        %WorkflowRight{}
        |> WorkflowRight.changeset(%{
          right: right,
          group: group,
          workflow_definition_id: workflow_definition_id
        })
        |> Repo.insert()
      end)
    end)
  end
end
