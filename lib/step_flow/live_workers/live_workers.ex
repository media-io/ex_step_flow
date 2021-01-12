defmodule StepFlow.LiveWorkers do
  @moduledoc """
  The LiveWorkers context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Repo

  alias StepFlow.LiveWorkers.LiveWorker

  @doc """
  Creates a Live Worker entry.

  ## Examples

      iex> create_live_worker(%{field: value})
      {:ok, %Job{}}

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
      %Job{}

      iex> get_by!(456)
      nil

  """
  def get_by!(%{"job_id" => job_id}) do
    Repo.get_by!(LiveWorker, job_id: job_id)
  end

  @doc """
  Gets a single live worker by job ID

  ## Examples

      iex> get_by(123)
      %Job{}

      iex> get_by(456)
      nil

  """
  def get_by(%{"job_id" => job_id}) do
    Repo.get_by(LiveWorker, job_id: job_id)
  end

  @doc """
  Updates a live worker.

  ## Examples

      iex> update_live_worker(job, %{field: new_value})
      {:ok, %Job{}}

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
      {:ok, %Job{}}

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
      %Ecto.Changeset{source: %Job{}}

  """
  def change_live_worker(%LiveWorker{} = live_worker) do
    LiveWorker.changeset(live_worker, %{})
  end
end
