defmodule StepFlow.Repo do
  use Ecto.Repo,
    otp_app: :step_flow,
    show_sensitive_data_on_connection_error: true,
    adapter: Ecto.Adapters.Postgres

  require Logger

  def init(_, opts) do
    opts =
      opts
      |> replace_if_present(:hostname)
      |> replace_if_present(:port)
      |> replace_if_present(:username)
      |> replace_if_present(:password)
      |> replace_if_present(:database)
      |> replace_if_present(:pool_size, &StepFlow.Configuration.to_integer/1)

    Logger.debug("StepFlow connecting to Postgres with parameters: #{inspect(opts)}")
    {:ok, opts}
  end

  defp replace_if_present(opts, key, processor \\ &StepFlow.Repo.bypass/1) do
    case StepFlow.Configuration.get_var_value(StepFlow.Repo, key) do
      nil ->
        opts

      value ->
        value = processor.(value)
        Keyword.put(opts, key, value)
    end
  end

  def bypass(value), do: value
end
