defmodule StepFlow.Api.WorkflowsTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias StepFlow.Repo
  alias StepFlow.Router
  alias StepFlow.WorkflowDefinitions.WorkflowDefinition
  alias StepFlow.Workflows
  doctest StepFlow

  @opts Router.init([])

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(StepFlow.Repo)
  end

  describe "workflow" do
    @unauthorized_user %{
      rights: [
        "unauthorized"
      ]
    }

    def workflow_fixture(workflow, attrs \\ %{}) do
      {:ok, workflow} =
        attrs
        |> Enum.into(workflow)
        |> Workflows.create_workflow()

      workflow
    end

    def workflow_definition_fixture(workflow_definition) do
      %WorkflowDefinition{}
      |> WorkflowDefinition.changeset(workflow_definition)
      |> Repo.insert()
    end

    test "GET /workflows with authorized user" do
      {status, _headers, body} =
        conn(:get, "/workflows")
        |> assign(:current_user, %{rights: ["user_view"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      assert body |> Jason.decode!() == %{"data" => [], "total" => 0}

      workflow_fixture(%{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3,
        rights: [
          %{
            action: "view",
            groups: ["user_view"]
          }
        ]
      })

      {status, _headers, body} =
        conn(:get, "/workflows")
        |> assign(:current_user, %{rights: ["user_view"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      assert body |> Jason.decode!() |> Map.get("total") == 1

      {status, _headers, body} =
        conn(:get, "/workflows")
        |> assign(:current_user, %{rights: ["user_update"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      assert body |> Jason.decode!() |> Map.get("total") == 0
    end

    test "GET /workflows with unauthorized user" do
      {status, _headers, body} =
        conn(:get, "/workflows")
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      assert body |> Jason.decode!() == %{"data" => [], "total" => 0}

      workflow_fixture(%{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3,
        rights: [
          %{
            action: "view",
            groups: ["user_view"]
          }
        ]
      })

      {status, _headers, body} =
        conn(:get, "/workflows")
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200
      assert body |> Jason.decode!() == %{"data" => [], "total" => 0}
    end

    @tag capture_log: true
    test "POST /workflows valid with authorized user" do
      {status, _headers, body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          parameters: %{}
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 201

      assert body
             |> Jason.decode!()
             |> Map.get("data")
             |> Map.get("reference") == "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"
    end

    @tag capture_log: true
    test "POST /workflows valid with unauthorized user" do
      {status, _headers, _body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          parameters: %{}
        })
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end

    @tag capture_log: true
    test "POST /workflows valid missing parameters" do
      {status, _headers, _body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 201
    end

    @tag capture_log: true
    test "POST /workflows invalid missing reference" do
      {status, _headers, _body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          parameters: %{}
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 422
    end

    @tag capture_log: true
    test "POST /workflows invalid missing reference and parameters" do
      {status, _headers, _body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow"
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 422
    end

    @tag capture_log: true
    test "POST /workflows valid with valid parameters" do
      {status, _headers, body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          parameters: %{
            "audio_source_filename" => "awsome.mp4"
          }
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 201

      assert body
             |> Jason.decode!()
             |> Map.get("data")
             |> Map.get("parameters")
             |> Enum.find(fn param -> param["id"] == "audio_source_filename" end)
             |> Map.get("value") == "awsome.mp4"
    end

    @tag capture_log: true
    test "POST /workflows valid with invalid parameter" do
      {status, _headers, body} =
        conn(:post, "/workflows", %{
          workflow_identifier: "simple_workflow",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          parameters: %{
            "invalid" => "parameter"
          }
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 201

      assert body
             |> Jason.decode!()
             |> Map.get("data")
             |> Map.get("identifier") == "simple_workflow"
    end

    test "[deprecated] POST /workflow invalid" do
      {status, _headers, body} =
        conn(:post, "/launch_workflow", %{})
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 422

      assert body |> Jason.decode!() == %{
               "errors" => [
                 %{
                   "message" => "Incorrect parameters",
                   "reason" => "Missing Workflow identifier parameter"
                 }
               ]
             }
    end

    test "[deprecated] POST /launch_workflow valid" do
      workflow_definition_fixture(%{
        identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
        version_major: 1,
        version_minor: 2,
        version_micro: 3,
        rights: [
          %{
            action: "create",
            groups: ["user_create"]
          }
        ]
      })

      {status, _headers, _body} =
        conn(:post, "/launch_workflow", %{
          workflow_identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"
        })
        |> assign(:current_user, %{rights: ["user_create"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 201
    end

    test "SHOW /workflows/:id with authorized user" do
      workflow_id =
        workflow_fixture(%{
          identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          version_major: 1,
          version_minor: 2,
          version_micro: 3,
          rights: [
            %{
              action: "view",
              groups: ["user_view"]
            }
          ]
        })
        |> Map.get(:id)
        |> Integer.to_string()

      {status, _headers, body} =
        conn(:get, "/workflows/" <> workflow_id)
        |> assign(:current_user, %{rights: ["user_view"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      data =
        body
        |> Jason.decode!()
        |> Map.get("data")

      identifier =
        data
        |> Map.get("identifier")

      assert identifier == "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"

      reference =
        data
        |> Map.get("reference")

      assert reference == "9A9F48E4-5585-4E8E-9199-CEFECF85CE14"
    end

    test "SHOW /workflows/:id with unauthorized user" do
      workflow_id =
        workflow_fixture(%{
          identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          version_major: 1,
          version_minor: 2,
          version_micro: 3,
          rights: [
            %{
              action: "view",
              groups: ["administrator"]
            }
          ]
        })
        |> Map.get(:id)
        |> Integer.to_string()

      {status, _headers, _body} =
        conn(:get, "/workflows/" <> workflow_id)
        |> assign(:current_user, @unauthorized_user)
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end

    test "UPDATE /workflows/:id with authorized user" do
      workflow_id =
        workflow_fixture(%{
          identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          version_major: 1,
          version_minor: 2,
          version_micro: 3,
          rights: [
            %{
              action: "update",
              groups: ["user_update"]
            }
          ]
        })
        |> Map.get(:id)
        |> Integer.to_string()

      {status, _headers, _body} =
        conn(:put, "/workflows/" <> workflow_id, %{workflow: %{reference: "updated reference"}})
        |> assign(:current_user, %{rights: ["user_update"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403
    end

    test "DELETE /workflows/:id" do
      workflow_id =
        workflow_fixture(%{
          identifier: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          reference: "9A9F48E4-5585-4E8E-9199-CEFECF85CE14",
          version_major: 1,
          version_minor: 2,
          version_micro: 3,
          rights: [
            %{
              action: "delete",
              groups: ["user_delete"]
            }
          ]
        })
        |> Map.get(:id)
        |> Integer.to_string()

      {status, _headers, body} =
        conn(:delete, "/workflows/" <> workflow_id)
        |> assign(:current_user, %{rights: ["user_update"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 403

      {status, _headers, body} =
        conn(:delete, "/workflows/" <> workflow_id)
        |> assign(:current_user, %{rights: ["user_delete"]})
        |> Router.call(@opts)
        |> sent_resp

      assert status == 204
      assert body == ""
    end

    test "GET /workflows_statistics" do
      {status, _headers, body} =
        conn(:get, "/workflows_statistics")
        |> Router.call(@opts)
        |> sent_resp

      assert status == 200

      assert body |> Jason.decode!() |> Map.get("data") |> length == 50
    end
  end
end
