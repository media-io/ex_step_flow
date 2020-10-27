defmodule StepFlow.WorkerDefinitionsTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.WorkerDefinitions
  alias StepFlow.WorkerDefinitions.WorkerDefinition

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    for model <- [WorkerDefinition], do: StepFlow.Repo.delete_all(model)
    :ok
  end

  doctest StepFlow.WorkerDefinitions

  describe "worker_definitions" do
    test "register a new worker" do
      "./test/worker_definitions/transfer_worker_description.json"
      |> File.read!()
      |> Jason.decode!()
      |> WorkerDefinitions.create_worker_definition()
      
      assert %{
          data: [_worker_description],
          page: 0,
          size: 10,
          total: 1,
        } = WorkerDefinitions.list_worker_definitions()

    end
  end
end
