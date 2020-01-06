defmodule StepFlow.WorkerDefinitions do
  @moduledoc """
  The WorkerDefinitions context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.WorkerDefinitions.WorkerDefinition

  @doc """
  Returns the list of WorkerDefinitions.

  ## Examples

      iex> StepFlow.WorkerDefinitions.list_worker_definitions()
      %{data: [], page: 0, size: 10, total: 0}

  """
  def list_worker_definitions(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query = from(worker_definition in WorkerDefinition)

    total_query = from(item in query, select: count(item.id))

    total =
      Repo.all(total_query)
      |> List.first()

    query =
      from(
        job in query,
        order_by: [desc: :inserted_at],
        offset: ^offset,
        limit: ^size
      )

    jobs = Repo.all(query)

    %{
      data: jobs,
      total: total,
      page: page,
      size: size
    }
  end

  @doc """
  Gets a single WorkerDefinition.

  Raises `Ecto.NoResultsError` if the WorkerDefinition does not exist.
  """
  def get_worker_definition!(id), do: Repo.get!(WorkerDefinition, id)

  @doc """
  Creates a WorkerDefinition.

  ## Examples

      iex> result = StepFlow.WorkerDefinitions.create_worker_definition(%{
      ...>   queue_name: "my_queue",
      ...>   label: "My Queue",
      ...>   version: "1.2.3",
      ...>   short_description: "short description",
      ...>   description: "long description",
      ...>   parameters: []
      ...> })
      ...> match?({:ok, %StepFlow.WorkerDefinitions.WorkerDefinition{}}, result)
      true

      iex> result = StepFlow.WorkerDefinitions.create_worker_definition(%{field: :bad_value})
      ...> match?({:error, %Ecto.Changeset{}}, result)
      true

  """
  def create_worker_definition(attrs \\ %{}) do
    %WorkerDefinition{}
    |> WorkerDefinition.changeset(attrs)
    |> Repo.insert()
  end

  def exists(%{"queue_name" => queue_name, "version" => version}) do
    case Repo.get_by(WorkerDefinition, queue_name: queue_name, version: version) do
      nil -> false
      _ -> true
    end
  end

  def exists(_), do: false
end
