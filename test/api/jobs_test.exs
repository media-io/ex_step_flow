defmodule StepFlow.Api.JobsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Router
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
    # Setting the shared mode
    Sandbox.mode(StepFlow.Repo, {:shared, self()})
  end

  test "GET /jobs" do
    {status, _headers, body} =
      conn(:get, "/jobs")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() == %{"data" => [], "total" => 0}

    # {status, _headers, _body} =
    #   conn(:post, "/workflows", %{
    #     identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
    #     reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
    #     version_major: 1,
    #     version_minor: 2,
    #     version_micro: 3
    #   })
    #   |> Router.call(@opts)
    #   |> sent_resp

    # assert status == 201

    # {status, _headers, body} =
    #   conn(:get, "/workflows")
    #   |> Router.call(@opts)
    #   |> sent_resp

    # assert status == 200
    # assert body |> Jason.decode!() |> Map.get("total") == 1
  end
end
