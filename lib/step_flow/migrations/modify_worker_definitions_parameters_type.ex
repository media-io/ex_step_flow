defmodule StepFlow.Migration.ModifyWorkerDefinitionsParametersType do
    use Ecto.Migration
    @moduledoc false
  
    def change do
        alter table(:step_flow_worker_definitions) do
            remove(:parameters)
        end

        alter table(:step_flow_worker_definitions) do
            add(:parameters, :map)
        end
    end
  end
  