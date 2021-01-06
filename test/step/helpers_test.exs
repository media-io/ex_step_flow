defmodule StepFlow.StepHelpersTest do
  use ExUnit.Case
  use Plug.Test

  alias StepFlow.Step.Helpers

  doctest StepFlow

  describe "helpers_test" do
    test "template generation" do
      template = "{work_directory}/{date_time}/{filename}"

      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000",
        parameters: []
      }

      step = %{
        name: "job_step"
      }

      source_path = "source_folder/filename.ttml"

      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, step, dates, source_path)
      assert generated == "/test_work_dir/2019_12_05__11_41_40/filename.ttml"
    end

    test "template generation with extension" do
      template = "{work_directory}/{date_time}/{name}{extension}"

      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000",
        parameters: []
      }

      step = %{
        name: "job_step"
      }

      source_path = "source_folder/filename.ttml"

      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, step, dates, source_path)
      assert generated == "/test_work_dir/2019_12_05__11_41_40/filename.ttml"
    end

    test "template generation with workflow parameters" do
      template = "{work_directory}/{title}/{name}{extension}"

      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000",
        parameters: [
          %{
            "id" => "source_prefix",
            "type" => "string",
            "value" => "/343079/http"
          },
          %{
            "id" => "title",
            "type" => "string",
            "value" => "content_title"
          }
        ]
      }

      step = %{
        name: "job_step"
      }

      source_path = "source_folder/filename.ttml"

      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, step, dates, source_path)
      assert generated == "/test_work_dir/content_title/filename.ttml"
    end

    test "template multiple source paths" do
      template = "{work_directory}/{title}/<%= Enum.at(source_paths, 1) |> Path.basename() %>"

      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000",
        parameters: [
          %{
            "id" => "source_prefix",
            "type" => "string",
            "value" => "/343079/http"
          },
          %{
            "id" => "title",
            "type" => "string",
            "value" => "content_title"
          }
        ]
      }

      step = %{
        name: "job_step"
      }

      source_paths = [
        "source_folder/filename.ttml",
        "source_folder/filename.mp4"
      ]

      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, step, dates, source_paths)
      assert generated == "/test_work_dir/content_title/filename.mp4"
    end

    test "custom work directory" do
      template = "{work_directory}/{title}/{name}{extension}"

      workflow = %{
        id: 666,
        reference: "110e8400-e29b-11d4-a716-446655440000",
        parameters: [
          %{
            "id" => "source_prefix",
            "type" => "string",
            "value" => "/343079/http"
          },
          %{
            "id" => "title",
            "type" => "string",
            "value" => "content_title"
          }
        ]
      }

      step = %{
        name: "job_step",
        work_dir: "/custom/work_dir"
      }

      source_path = "source_folder/filename.ttml"

      dates = %{
        date: "2019_12_05",
        date_time: "2019_12_05__11_41_40"
      }

      generated = Helpers.template_process(template, workflow, step, dates, source_path)
      assert generated == "/custom/work_dir/content_title/filename.ttml"
    end
  end
end
