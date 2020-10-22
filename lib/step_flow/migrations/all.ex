defmodule StepFlow.Migration.All do
  @moduledoc false

  def apply_migrations do
    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_011_180_000,
      StepFlow.Migration.CreateWorkflow
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_011_180_100,
      StepFlow.Migration.CreateJobs
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_011_180_200,
      StepFlow.Migration.CreateStatus
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_011_180_300,
      StepFlow.Migration.CreateArtifacts
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_022_164_200,
      StepFlow.Migration.CreateWorkerDefinitions
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_191_022_164_200,
      StepFlow.Migration.CreateWorkerDefinitions
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_200_130_170_300,
      StepFlow.Migration.CreateProgressions
    )

    Ecto.Migrator.up(
      StepFlow.Repo,
      20_201_020_140_300,
      StepFlow.Migration.ModifyWorkerDefinitionsParametersType
    )
  end
end
