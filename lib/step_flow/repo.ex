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
          case System.get_env("DATABASE_HOSTNAME") do
            nil ->
              opts

            hostname ->
              Keyword.put(opts, :hostname, hostname)
          end

        opts =
          case System.get_env("DATABASE_PORT") do
            nil ->
              opts

            port ->
              Keyword.put(opts, :port, port)
          end

        opts =
          case System.get_env("DATABASE_USERNAME") do
            nil ->
              opts

            username ->
              Keyword.put(opts, :username, username)
          end

        opts =
          case System.get_env("DATABASE_PASSWORD") do
            nil ->
              opts

            password ->
              Keyword.put(opts, :password, password)
          end

        opts =
          case System.get_env("DATABASE_NAME") do
            nil ->
              opts

            database ->
              Keyword.put(opts, :database, database)
          end

        Logger.info("connect to #{inspect(opts)}")
        {:ok, opts}

      url ->
        Logger.info("connect to #{url}")
        {:ok, Keyword.put(opts, :url, url)}
    end
  end
end
