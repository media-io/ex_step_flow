defmodule StepFlow.WorkflowsTest do
  use ExUnit.Case, async: true
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

  test "GET /workflows/00000000-0000-0000-0000-000000000000" do
    {status, _headers, body} =
      conn(:get, "/workflows/00000000-0000-0000-0000-000000000000")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() == %{}
  end

  test "POST /workflows invalid" do
    {status, _headers, body} =
      conn(:post, "/workflows", %{})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422

    assert body |> Jason.decode!() == %{
             "errors" => %{
               "identifier" => ["can't be blank"],
               "reference" => ["can't be blank"],
               "version_major" => ["can't be blank"],
               "version_micro" => ["can't be blank"],
               "version_minor" => ["can't be blank"]
             }
           }
  end

  test "POST /workflows valid" do
    {status, _headers, _body} =
      conn(:post, "/workflows", %{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201
  end

  test "GET /workflows/statistics" do
    {status, _headers, body} =
      conn(:get, "/workflows/statistics")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    assert body |> Jason.decode!() |> Map.get("data") |> length == 50
  end
end
