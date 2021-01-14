defmodule StepFlow.LiveWorkers do
  @moduledoc """
  The LiveWorkers context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.LiveWorkers.LiveWorker

  @doc """
  Returns the list of Live Worker.

  ## Examples

      iex> StepFlow.LiveWorkers.list_live_workers()
      %{data: [], page: 0, size: 10, total: 0}

  """
  def list_live_workers(params \\ %{}) do
    page =
      Map.get(params, "page", 0)
      |> StepFlow.Integer.force()

    size =
      Map.get(params, "size", 10)
      |> StepFlow.Integer.force()

    offset = page * size

    query = from(live_worker in LiveWorker)

    query =
      case Map.get(params, "initializing") do
        nil ->
          from(worker in query)

        _ ->
          from(
            worker in query,
            where: (fragment("? = array[]::character varying[]", worker.ips) or
              is_nil(worker.creation_date)) and
              is_nil(worker.termination_date)
          )
      end

    query =
      case Map.get(params, "started") do
        nil ->
          from(worker in query)

        _ ->
          from(
            worker in query,
            where: fragment("array_length(?, 1)", worker.ips) > 0 and
              not is_nil(worker.creation_date) and
              is_nil(worker.termination_date)
          )
      end

    query =
      case Map.get(params, "terminated") do
        nil ->
          from(worker in query)

        _ ->
          from(
            worker in query,
            where: not is_nil(worker.termination_date)
          )
      end

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
  Creates a Live Worker entry.

  ## Examples

      iex> create_live_worker(%{field: value})
      {:ok, %LiveWorker{}}

      iex> create_live_worker(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_live_worker(attrs \\ %{}) do
    %LiveWorker{}
    |> LiveWorker.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single live worker by job ID

  ## Examples

      iex> get_by!(123)
      %LiveWorker{}

      iex> get_by!(456)
      nil

  """
  def get_by!(%{"job_id" => job_id}) do
    Repo.get_by!(LiveWorker, job_id: job_id)
  end

  @doc """
  Gets a single live worker by job ID

  ## Examples

      iex> get_by(%{"job_id" => 123})
      %LiveWorker{}

      iex> get_by(%{"job_id" => 456})
      nil

  """
  def get_by(%{"job_id" => job_id}) do
    Repo.get_by(LiveWorker, job_id: job_id)
  end

  @doc """
  Updates a live worker.

  ## Examples

      iex> update_live_worker(job, %{field: new_value})
      {:ok, %LiveWorker{}}

      iex> update_live_worker(job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_live_worker(%LiveWorker{} = live_worker, attrs) do
    live_worker
    |> LiveWorker.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a LiveWorker.

  ## Examples

      iex> delete_live_worker(live_worker)
      {:ok, %LiveWorker{}}

      iex> delete_live_worker(live_worker)
      {:error, %Ecto.Changeset{}}

  """
  def delete_live_worker(%LiveWorker{} = live_worker) do
    Repo.delete(live_worker)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking live worker changes.

  ## Examples

      iex> change_live_worker(job)
      %Ecto.Changeset{source: %LiveWorker{}}

  """
  def change_live_worker(%LiveWorker{} = live_worker) do
    LiveWorker.changeset(live_worker, %{})
  end
end
