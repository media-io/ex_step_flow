defmodule StepFlow.Jobs.StatusTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Jobs.Status

  doctest StepFlow

  test "get queued state enum label" do
    assert "queued" == Status.state_enum_label(:queued)
    assert "queued" == Status.state_enum_label(0)
  end

  test "get queued state from label" do
    assert :queued == Status.state_enum_from_label("queued")
  end

  test "get skipped state enum label" do
    assert "skipped" == Status.state_enum_label(:skipped)
    assert "skipped" == Status.state_enum_label(1)
  end

  test "get skipped state from label" do
    assert :skipped == Status.state_enum_from_label("skipped")
  end

  test "get processing state enum label" do
    assert "processing" == Status.state_enum_label(:processing)
    assert "processing" == Status.state_enum_label(2)
  end

  test "get processing state from label" do
    assert :processing == Status.state_enum_from_label("processing")
  end

  test "get retrying state enum label" do
    assert "retrying" == Status.state_enum_label(:retrying)
    assert "retrying" == Status.state_enum_label(3)
  end

  test "get retrying state from label" do
    assert :retrying == Status.state_enum_from_label("retrying")
  end

  test "get error state enum label" do
    assert "error" == Status.state_enum_label(:error)
    assert "error" == Status.state_enum_label(4)
  end

  test "get error state from label" do
    assert :error == Status.state_enum_from_label("error")
  end

  test "get completed state enum label" do
    assert "completed" == Status.state_enum_label(:completed)
    assert "completed" == Status.state_enum_label(5)
  end

  test "get completed state from label" do
    assert :completed == Status.state_enum_from_label("completed")
  end

  test "get unknown state enum label" do
    assert "unknown" == Status.state_enum_label(:other)
    assert "unknown" == Status.state_enum_label(6)
    assert "unknown" == Status.state_enum_label(nil)
  end

  test "get unknown state from label" do
    assert nil == Status.state_enum_from_label("unknown")
  end
end
