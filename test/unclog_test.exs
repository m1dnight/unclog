defmodule UnclogTest do
  use ExUnit.Case, async: true

  describe "nest_changelog/2" do
    test "places top-level content under :__logs__" do
      result = Unclog.nest_changelog(%{}, {[], "preamble.md", "# Changelog"})

      assert result == %{:__logs__ => ["# Changelog"]}
    end

    test "creates a nested map for a single topic" do
      result = Unclog.nest_changelog(%{}, {["0.1.0"], "summary.md", "first release"})

      assert result == %{
               "0.1.0" => %{:__logs__ => ["first release"]}
             }
    end

    test "creates intermediate topics for nested paths" do
      result = Unclog.nest_changelog(%{}, {["0.1.0", "features"], "a.md", "feature a"})

      assert result == %{
               "0.1.0" => %{
                 :__logs__ => [],
                 "features" => %{:__logs__ => ["feature a"]}
               }
             }
    end

    test "appends additional logs to an existing topic in insertion order" do
      result =
        %{}
        |> Unclog.nest_changelog({["0.1.0", "features"], "a.md", "feature a"})
        |> Unclog.nest_changelog({["0.1.0", "features"], "b.md", "feature b"})

      assert get_in(result, ["0.1.0", "features", :__logs__]) == ["feature a", "feature b"]
    end
  end

  describe "nest_changelogs/1" do
    test "merges multiple entries into a single nested map" do
      result =
        Unclog.nest_changelogs([
          {[], "preamble.md", "# Changelog"},
          {["0.1.0"], "summary.md", "first release"},
          {["0.1.0", "features"], "a.md", "feature a"},
          {["0.1.0", "features"], "b.md", "feature b"},
          {["0.1.1"], "summary.md", "second release"}
        ])

      assert result == %{
               :__logs__ => ["# Changelog"],
               "0.1.0" => %{
                 :__logs__ => ["first release"],
                 "features" => %{:__logs__ => ["feature a", "feature b"]}
               },
               "0.1.1" => %{:__logs__ => ["second release"]}
             }
    end
  end

  describe "prune_empty_topics/1" do
    test "drops a subtopic whose logs are all blank" do
      input = %{
        :__logs__ => ["# Changelog"],
        "0.1.1" => %{
          :__logs__ => ["summary"],
          "features" => %{:__logs__ => ["", "  \n"]}
        }
      }

      assert Unclog.prune_empty_topics(input) == %{
               :__logs__ => ["# Changelog"],
               "0.1.1" => %{:__logs__ => ["summary"]}
             }
    end

    test "drops the parent when all of its descendants are blank" do
      input = %{
        :__logs__ => ["# Changelog"],
        "0.1.1" => %{
          :__logs__ => [""],
          "features" => %{:__logs__ => [""]},
          "bug-fixes" => %{:__logs__ => [""]}
        }
      }

      assert Unclog.prune_empty_topics(input) == %{:__logs__ => ["# Changelog"]}
    end

    test "keeps a subtopic when at least one descendant has content" do
      input = %{
        :__logs__ => [],
        "0.1.1" => %{
          :__logs__ => [""],
          "features" => %{:__logs__ => ["a feature"]},
          "bug-fixes" => %{:__logs__ => [""]}
        }
      }

      assert Unclog.prune_empty_topics(input) == %{
               :__logs__ => [],
               "0.1.1" => %{
                 :__logs__ => [""],
                 "features" => %{:__logs__ => ["a feature"]}
               }
             }
    end

    test "preserves the root even when everything else prunes away" do
      input = %{
        :__logs__ => [],
        "0.1.1" => %{:__logs__ => [""]}
      }

      assert Unclog.prune_empty_topics(input) == %{:__logs__ => []}
    end

    test "is a no-op when nothing is empty" do
      input = %{
        :__logs__ => ["# Changelog"],
        "0.1.0" => %{
          :__logs__ => ["first release"],
          "features" => %{:__logs__ => ["scaffolding"]}
        }
      }

      assert Unclog.prune_empty_topics(input) == input
    end
  end

  describe "generate_template/2" do
    test "renders topic headers and content with versions sorted descending" do
      input = %{
        :__logs__ => ["# Changelog"],
        "0.1.0" => %{
          :__logs__ => ["first release"],
          "features" => %{:__logs__ => ["scaffolding"]}
        },
        "0.1.1" => %{:__logs__ => ["second release"]}
      }

      output = input |> Unclog.generate_template() |> Enum.join("\n")

      assert output == """
             # Changelog

             ## 0.1.1

             second release

             ## 0.1.0

             first release

             ### Features

             scaffolding
             """
    end

    test "prettifies dashes and underscores in topic names" do
      input = %{
        :__logs__ => [],
        "0.1.0" => %{
          :__logs__ => [],
          "bug-fixes" => %{:__logs__ => ["fix"]},
          "breaking_changes" => %{:__logs__ => ["bc"]}
        }
      }

      output = input |> Unclog.generate_template() |> Enum.join("\n")

      assert output =~ "### Bug fixes"
      assert output =~ "### Breaking changes"
    end

    test "respects the starting depth argument" do
      input = %{
        :__logs__ => [],
        "section" => %{:__logs__ => ["body"]}
      }

      output = input |> Unclog.generate_template(4) |> Enum.join("\n")

      assert output =~ "#### Section"
    end
  end

  describe "changelogs/1" do
    setup do
      tmp = Path.join(System.tmp_dir!(), "unclog_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf!(tmp) end)
      {:ok, tmp: tmp}
    end

    test "reads markdown files into a nested map keyed by directory", %{tmp: tmp} do
      File.write!(Path.join(tmp, "0.preamble.md"), "# Changelog")
      File.mkdir_p!(Path.join(tmp, "0.1.0/features"))
      File.write!(Path.join(tmp, "0.1.0/summary.md"), "first release")
      File.write!(Path.join(tmp, "0.1.0/features/a.md"), "feature a")

      result = Unclog.changelogs(tmp)

      assert result[:__logs__] == ["# Changelog"]
      assert get_in(result, ["0.1.0", :__logs__]) == ["first release"]
      assert get_in(result, ["0.1.0", "features", :__logs__]) == ["feature a"]
    end

    test "ignores non-markdown files", %{tmp: tmp} do
      File.write!(Path.join(tmp, "notes.txt"), "ignore me")
      File.write!(Path.join(tmp, "0.preamble.md"), "# Changelog")

      result = Unclog.changelogs(tmp)

      assert result == %{:__logs__ => ["# Changelog"]}
    end

    test "end-to-end: prune + generate suppresses empty scaffolding sections", %{tmp: tmp} do
      File.write!(Path.join(tmp, "0.preamble.md"), "# Changelog")

      File.mkdir_p!(Path.join(tmp, "0.1.1/features"))
      File.mkdir_p!(Path.join(tmp, "0.1.1/bug-fixes"))
      File.write!(Path.join(tmp, "0.1.1/summary.md"), "second release")
      File.write!(Path.join(tmp, "0.1.1/features/change.md"), "")
      File.write!(Path.join(tmp, "0.1.1/bug-fixes/change.md"), "")

      output =
        tmp
        |> Unclog.changelogs()
        |> Unclog.prune_empty_topics()
        |> Unclog.generate_template()
        |> Enum.join("\n")

      refute output =~ "### Features"
      refute output =~ "### Bug fixes"
      assert output =~ "## 0.1.1"
      assert output =~ "second release"
    end
  end
end
