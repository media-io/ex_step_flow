defmodule StepFlow.WorkerDefinitionsTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.WorkerDefinitions.WorkerDefinition

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    for model <- [WorkerDefinition], do: StepFlow.Repo.delete_all(model)
    :ok
  end

  doctest StepFlow.WorkerDefinitions
end
