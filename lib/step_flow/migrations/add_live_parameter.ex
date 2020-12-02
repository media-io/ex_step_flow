defmodule StepFlow.Migration.AddLiveParameter do
  use Ecto.Migration
  @moduledoc false

  def change do
    alter table(:step_flow_workflow_definition) do
      add(:is_live, :boolean, default: false)
    end

    alter table(:step_flow_workflow) do
      add(:is_live, :boolean, default: false)
    end

    alter table(:step_flow_jobs) do
      add(:is_live, :boolean, default: false)
    end
  end
end
