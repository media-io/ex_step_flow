defmodule StepFlow.Api.WorkerDefinitionsTest do
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

  test "GET /worker_definitions" do
    {status, _headers, body} =
      conn(:get, "/worker_definitions")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() == %{"data" => [], "total" => 0}

    {status, _headers, _body} =
      conn(:post, "/worker_definitions", %{
        queue_name: "my_queue",
        label: "My Queue",
        version: "1.2.3",
        git_version: "1.2.3",
        short_description: "short description",
        description: "long description",
        parameters: []
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    {status, _headers, body} =
      conn(:get, "/worker_definitions")
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200
    assert body |> Jason.decode!() |> Map.get("total") == 1
  end

  test "POST /worker_definitions invalid" do
    {status, _headers, body} =
      conn(:post, "/worker_definitions", %{})
      |> Router.call(@opts)
      |> sent_resp

    assert status == 422

    assert body |> Jason.decode!() == %{
             "errors" => %{
               "queue_name" => ["can't be blank"],
               "label" => ["can't be blank"],
               "version" => ["can't be blank"],
               "git_version" => ["can't be blank"],
               "short_description" => ["can't be blank"],
               "description" => ["can't be blank"]
             }
           }
  end

  test "POST /worker_definitions valid" do
    {status, _headers, _body} =
      conn(:post, "/worker_definitions", %{
        queue_name: "my_queue",
        label: "My Queue",
        version: "1.2.3",
        git_version: "1.2.3",
        short_description: "short description",
        description: "long description"
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201
  end

  test "SHOW /worker_definitions/:id" do
    {status, _headers, body} =
      conn(:post, "/worker_definitions", %{
        queue_name: "my_queue",
        label: "My Queue",
        version: "1.2.3",
        git_version: "1.2.3",
        short_description: "short description",
        description: "long description"
      })
      |> Router.call(@opts)
      |> sent_resp

    assert status == 201

    workflow_id =
      body
      |> Jason.decode!()
      |> Map.get("data")
      |> Map.get("id")
      |> Integer.to_string()

    {status, _headers, body} =
      conn(:get, "/worker_definitions/" <> workflow_id)
      |> Router.call(@opts)
      |> sent_resp

    assert status == 200

    data =
      body
      |> Jason.decode!()
      |> Map.get("data")

    queue_name =
      data
      |> Map.get("queue_name")

    assert queue_name == "my_queue"

    version =
      data
      |> Map.get("version")

    assert version == "1.2.3"
  end
end
