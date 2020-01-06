defmodule StepFlow.Migration.CreateWorkerDefinitions do
  use Ecto.Migration
  @moduledoc false

  def change do
    create table(:step_flow_worker_definitions) do
      add(:queue_name, :string)
      add(:label, :string)
      add(:version, :string)
      add(:short_description, :string)
      add(:description, :text)
      add(:parameters, {:array, :map}, default: [])

      timestamps()
    end
  end
end
