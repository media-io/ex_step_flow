defmodule StepFlow.Api.RootTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  test "GET /" do
    {status, _headers, body} =
      conn(:get, "/")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body == "Welcome to Step Flow"
  end

  test "GET /unknown" do
    {status, _headers, body} =
      conn(:get, "/unknown")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 404
    assert body == "Not found"
  end
end
