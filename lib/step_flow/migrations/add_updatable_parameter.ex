defmodule StepFlow.Migration.AddUpdatableParameter do
  use Ecto.Migration
  @moduledoc false

  def change do
    alter table(:step_flow_jobs) do
      add(:is_updatable, :boolean, default: false)
    end
  end
end
