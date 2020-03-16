defmodule StepFlow.Authorization do
  @moduledoc """
  StepFlow provide an entire system to manage workflows.  
  It provides differents parts:
  - Connection with a database using Ecto to store Workflow status
  - a connection with a message broker to interact with workers
  - a RESTful API to create, list and interact with workflows
  """

  use Plug.Builder
  plug(Plug.Logger)
  require Logger

  @doc """
  Check authorization for the connection using the method and the path.
  It can be configured using:
  ```elixir
    config :step_flow,
      authorize: [
        module: ExBackendWeb.Authorize,
        get_jobs: [:user_check, :specific_right_check]
      ]
  ```
  """
  def check(conn) do
    key = String.to_atom(String.downcase(conn.method) <> "_" <> get_path(conn.path_info))

    authorize = Application.get_env(:step_flow, StepFlow)[:authorize]

    if authorize &&
         Keyword.has_key?(authorize, :module) &&
         Keyword.has_key?(authorize, key) do
      check_for_route(conn, Keyword.get(authorize, :module), Keyword.get(authorize, key))
    else
      conn
    end
  end

  defp check_for_route(conn, _module, []), do: conn

  defp check_for_route(conn, module, [check | checks]) do
    Logger.info("#{__MODULE__}: Check authorization with #{module}.#{check}")
    conn = Kernel.apply(module, check, [conn, %{}])

    if conn.halted do
      conn
    else
      check_for_route(conn, module, checks)
    end
  end

  defp get_path(["workflows", _, "events"]) do
    "workflows_events"
  end

  defp get_path(items) do
    List.first(items)
  end
end
