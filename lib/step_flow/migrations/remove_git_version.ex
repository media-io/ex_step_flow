defmodule StepFlow.Migration.RemoveGitVersion do
  use Ecto.Migration
  @moduledoc false

  def change do
    alter table(:step_flow_worker_definitions) do
      remove(:git_version)
    end
  end
end
