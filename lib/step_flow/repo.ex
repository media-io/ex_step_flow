defmodule StepFlow.Repo do
  use Ecto.Repo,
    otp_app: :step_flow,
    show_sensitive_data_on_connection_error: true,
    adapter: Ecto.Adapters.Postgres

  require Logger

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    case System.get_env("DATABASE_URL") do
      nil ->
        opts =
          opts
          |> get_from_env("DATABASE_HOSTNAME", :hostname)
          |> get_from_env("DATABASE_PORT", :port)
          |> get_from_env("DATABASE_USERNAME", :username)
          |> get_from_env("DATABASE_PASSWORD", :password)
          |> get_from_env("DATABASE_NAME", :database)

        Logger.info("connect to #{inspect(opts)}")
        {:ok, opts}

      url ->
        Logger.info("connect to #{url}")
        {:ok, Keyword.put(opts, :url, url)}
    end
  end

  defp get_from_env(opts, env_var_name, key_in_opts) do
    case System.get_env(env_var_name) do
      nil ->
        opts

      value ->
        Keyword.put(opts, key_in_opts, value)
    end
  end
end
