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

  test "get unknown state enum label" do
    assert "unknown" == Status.state_enum_label(:other)
    assert "unknown" == Status.state_enum_label(6)
    assert "unknown" == Status.state_enum_label(nil)
  end

  test "get last status" do
    status_list = [
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:15:00],
        job_id: 123,
        state: "queued",
        updated_at: ~N[2020-01-14 15:15:00]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:17:32],
        job_id: 123,
        state: "skipped",
        updated_at: ~N[2020-01-14 15:17:32]
      },
      %{
        description: %{},
        id: 456,
        inserted_at: ~N[2020-01-14 15:16:03],
        job_id: 123,
        state: "processing",
        updated_at: ~N[2020-01-14 15:16:03]
      }
    ]

    last_status = Status.get_last_status(status_list)

    assert "skipped" == last_status.state
  end
end
