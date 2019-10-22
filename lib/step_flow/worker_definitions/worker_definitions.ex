defmodule StepFlow.WorkerDefinitions do
  @moduledoc """
  The WorkerDefinitions context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.WorkerDefinitions.WorkerDefinition

  defp force_integer(param) when is_bitstring(param) do
    param
    |> String.to_integer()
  end

  defp force_integer(param) do
    param
  end

  @doc """
  Returns the list of WorkerDefinitions.

  ## Examples

      iex> list_worker_definitions()
      [%WorkerDefinition{}, ...]

  """
  def list_worker_definitions(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> force_integer

    size =
      Map.get(params, "size", 10)
      |> force_integer

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

  ## Examples

      iex> get_worker_definition!(123)
      %WorkerDefinition{}

      iex> get_worker_definition!(456)
      ** (Ecto.NoResultsError)

  """
  def get_worker_definition!(id), do: Repo.get!(WorkerDefinition, id)

  @doc """
  Creates a WorkerDefinition.

  ## Examples

      iex> create_worker_definition(%{field: value})
      {:ok, %WorkerDefinition{}}

      iex> create_worker_definition(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

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
