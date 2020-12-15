defmodule StepFlow.Updates do
  @moduledoc """
  The Updates context.
  """

  import Ecto.Query, warn: false
  alias StepFlow.Jobs
  alias StepFlow.Jobs.Status
  alias StepFlow.Repo
  alias StepFlow.Updates.Update

  @doc """
  Creates an update.

  ## Examples

      iex> create_update(%{field: value})
      {:ok, %Update{}}

      iex> create_update(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update(attrs \\ %{}) do
    %Update{}
    |> Update.changeset(attrs)
    |> Repo.insert()
  end

  def update_parameters(job, parameters) do
    update_parameter(job, parameters)
    Status.set_job_status(job.id, :update, "Updated parameters: " ++ parameters)

    create_update(%{
      job_id: job.id,
      datetime: NaiveDateTime.utc_now(),
      parameters: parameters
    })
  end

  def update_parameter(job, [parameter | parameters]) do
    Jobs.update_job(job, parameter)
    update_parameter(job, parameters)
  end

  def update_parameter(_job, []), do: nil
end
