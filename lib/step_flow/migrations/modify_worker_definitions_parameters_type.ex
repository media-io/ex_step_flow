defmodule StepFlow.Migration.ModifyWorkerDefinitionsParametersType do
    use Ecto.Migration
    @moduledoc false
  
    def change do
        drop_if_exists table(:step_flow_worker_definitions)

        create table(:step_flow_worker_definitions) do
            add(:queue_name, :string)
            add(:label, :string)
            add(:version, :string)
            add(:short_description, :string)
            add(:description, :text)
            add(:parameters, :map, default: %{})
      
            timestamps()
        end
    end
  end
  