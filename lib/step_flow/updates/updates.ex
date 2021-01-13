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
    job_parameters =
      job.parameters
      |> update_parameter(parameters)

    Jobs.update_job(job, %{parameters: job_parameters})
    Status.set_job_status(job.id, :update, "Updating parameters")

    create_update(%{
      job_id: job.id,
      datetime: NaiveDateTime.utc_now(),
      parameters: parameters
    })
  end

  def update_parameter(job_parameters, [parameter | parameters]) do
    Enum.map(job_parameters, fn x ->
      if x["id"] == parameter.id do
        x
        |> Map.replace("value", parameter.value)
      else
        x
      end
    end)
    |> update_parameter(parameters)
  end

  def update_parameter(job_parameters, []), do: job_parameters
end
