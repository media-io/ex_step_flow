defmodule StepFlow.Jobs.StatusTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Jobs.Status

  doctest StepFlow

  test "get queued state enum label" do
    assert "queued" == Status.state_enum_label(:queued)
    assert "queued" == Status.state_enum_label(0)
  end

  test "get skipped state enum label" do
    assert "skipped" == Status.state_enum_label(:skipped)
    assert "skipped" == Status.state_enum_label(1)
  end

  test "get processing state enum label" do
    assert "processing" == Status.state_enum_label(:processing)
    assert "processing" == Status.state_enum_label(2)
  end

  test "get retrying state enum label" do
    assert "retrying" == Status.state_enum_label(:retrying)
    assert "retrying" == Status.state_enum_label(3)
  end

  test "get error state enum label" do
    assert "error" == Status.state_enum_label(:error)
    assert "error" == Status.state_enum_label(4)
  end

  test "get completed state enum label" do
    assert "completed" == Status.state_enum_label(:completed)
    assert "completed" == Status.state_enum_label(5)
  end

  test "get ready_to_init state enum label" do
    assert "ready_to_init" == Status.state_enum_label(:ready_to_init)
    assert "ready_to_init" == Status.state_enum_label(6)
  end

  test "get ready_to_start state enum label" do
    assert "ready_to_start" == Status.state_enum_label(:ready_to_start)
    assert "ready_to_start" == Status.state_enum_label(7)
  end

  test "get update state enum label" do
    assert "update" == Status.state_enum_label(:update)
    assert "update" == Status.state_enum_label(8)
  end

  test "get stopped state enum label" do
    assert "stopped" == Status.state_enum_label(:stopped)
    assert "stopped" == Status.state_enum_label(9)
  end

  test "get unknown state enum label" do
    assert "unknown" == Status.state_enum_label(:other)
    assert "unknown" == Status.state_enum_label(10)
    assert "unknown" == Status.state_enum_label(nil)
  end

  test "get last status" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: :skipped,
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    last_status = Status.get_last_status(status_list)

    assert :skipped == last_status.state
  end

  test "get create action" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:17:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    action =
      Status.get_last_status(status_list)
      |> Status.get_action()

    assert "create" == action
  end

  test "get init action" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: :ready_to_init,
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    action =
      Status.get_last_status(status_list)
      |> Status.get_action()

    assert "init_process" == action
  end

  test "get start action" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: :ready_to_start,
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    action =
      Status.get_last_status(status_list)
      |> Status.get_action()

    assert "start_process" == action
  end

  test "get delete action" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: :stopped,
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    action =
      Status.get_last_status(status_list)
      |> Status.get_action()

    assert "delete" == action
  end

  test "get action parameter" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: :queued,
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: :stopped,
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: :processing,
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    action =
      Status.get_last_status(status_list)
      |> Status.get_action_parameter()

    assert [%{"id" => "action", "type" => "string", "value" => "delete"}] == action
  end
end
