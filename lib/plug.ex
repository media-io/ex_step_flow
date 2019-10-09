defmodule StepFlow.Plug do
  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> Plug.Conn.assign(:name, Keyword.get(opts, :name, "Background Job"))
    |> StepFlow.Router.call(opts)
  end
end
