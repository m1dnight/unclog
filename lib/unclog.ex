defmodule Unclog do
  @moduledoc """
  Unclog helps you create and manage complex changelog files by separating them into files.

  For each change you make, or topic you work on, you can create a scaffolding directory to put in the changes.
  Based on these files, a single `CHANGELOG.md` file is generated.

  This project is inspired by [unclog](https://crates.io/crates/unclog) for Rust.




  ## Getting Started

  To create the initial scaffolding for your project, initialize a directory tree.

  ```shell
  mix unclog --init
  ```

  To create your first changelog entry, create the boilerplate scaffolding.

  ```shell
  mix unclog --create first_release
  ```

  When you are done editing the changelogs, generate the final `CHANGELOG.md` file.

  ```shell
  mix unclog --generate
  ```

  """

  @doc """
  Generates the changelog content and writes it to disk.
  """
  @spec write_changelog() :: :ok | {:error, :failed_to_write_changelog}
  def write_changelog do
    Unclog.changelogs(root_path())
    |> Unclog.prune_empty_topics()
    |> Unclog.generate_template()
    |> Enum.join("\n")
    |> Unclog.write_changelog()
  end

  defp root_path, do: Application.get_env(:unclog, :root, ".changelogs")
  defp output_path, do: Application.get_env(:unclog, :output, "CHANGELOG.md")

  @doc """
  Removes subtopics whose logs (and all descendant logs) are blank, so that
  empty scaffolding directories don't render as orphan headers.

  The root map is always kept, even if everything under it prunes away.
  """
  @spec prune_empty_topics(map()) :: map()
  def prune_empty_topics(map) do
    case do_prune(map) do
      :empty -> %{:__logs__ => []}
      pruned -> pruned
    end
  end

  defp do_prune(map) do
    {logs, subtopics} = Map.pop(map, :__logs__, [])

    pruned_subtopics =
      subtopics
      |> Enum.map(fn {k, v} -> {k, do_prune(v)} end)
      |> Enum.reject(fn {_k, v} -> v == :empty end)
      |> Map.new()

    has_logs? = Enum.any?(logs, &(String.trim(&1) != ""))

    if has_logs? or map_size(pruned_subtopics) > 0 do
      Map.put(pruned_subtopics, :__logs__, logs)
    else
      :empty
    end
  end

  @doc """
  Generate a nested map of changelogs.
  """
  @spec changelogs(String.t()) :: map()
  def changelogs(changelogs_path) do
    Path.wildcard(Path.join(changelogs_path, "/**/*.md"))
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # Get the relative path from changelogs directory
          relative_path = Path.relative_to(file, changelogs_path)

          path = Path.dirname(relative_path)

          filename = Path.basename(relative_path)
          # Split into components and remove the .md extension
          path_components =
            path
            |> Path.split()
            |> Enum.reject(&(&1 == "."))
            |> Enum.map(&Path.rootname(&1, ".md"))

          [{path_components, filename, content}]

        {:error, _} ->
          []
      end
    end)
    |> nest_changelogs()
  end

  @doc """
  Given a list of changelogs, returns a map of nested changelogs representing the directory structure.

  ## Example

  ```
  iex> Unclog.changelogs("./.changelogs")
  %{
    :__logs__ => ["", "# Changelog"],
    "foo" => %{
      :__logs__ => ["Wednesday, April 16, 2025"],
      "breaking_changes" => %{__logs__: [""]},
      "bug-fixes" => %{__logs__: [""]},
      "features" => %{__logs__: [""]}
    }
  }
  ```
  """
  @spec nest_changelogs([{[String.t()], String.t(), String.t()}]) :: map()
  def nest_changelogs(changelogs) do
    Enum.reduce(changelogs, %{}, fn changelog, acc -> nest_changelog(acc, changelog) end)
  end

  @doc """
  Given a dictionary of topics, places the given changelog nested into that dictionary.
  """
  @spec nest_changelog(map(), {[String.t()], String.t(), String.t()}) :: map()
  def nest_changelog(dict, {topics, _filename, content}) do
    # create a scan of the topics
    # to get a list of all prefixes in order
    # e.g., [1, 2, 3] -> [[1], [1, 2], [1, 2, 3]]
    topic_prefixes = Enum.scan(topics, [], &(&2 ++ [&1]))

    # ensure these topics all exist in the acc
    dict =
      Enum.reduce(topic_prefixes, dict, fn topics, acc ->
        case get_in(acc, topics) do
          nil -> put_in(acc, topics, %{:__logs__ => []})
          _ -> acc
        end
      end)

    case topics do
      [] ->
        Map.update(dict, :__logs__, [content], &(&1 ++ [content]))

      topics ->
        update_in(dict, topics, fn map ->
          Map.update(map, :__logs__, [content], &(&1 ++ [content]))
        end)
    end
  end

  @doc """
  Generates markdown file content based on the given topic map.
  """
  @spec generate_template(map(), non_neg_integer()) :: [String.t()]
  def generate_template(topic_map, depth \\ 2) do
    {changelogs, topic_map} = Map.pop(topic_map, :__logs__, [])
    # sort the topics from new to old
    topic_map = Enum.sort_by(topic_map, fn {topic, _} -> topic end, :desc)

    subtopics =
      Enum.reduce(topic_map, [], fn {topic, subtopics}, acc ->
        acc = acc ++ ["#{String.duplicate("#", depth)} #{pretty_topic(topic)}\n"]
        subtopics = generate_template(subtopics, depth + 1)
        acc ++ subtopics
      end)

    Enum.map(changelogs, fn changelog ->
      "#{changelog}\n"
    end) ++ subtopics
  end

  @doc """
  Writes the content of the markdown file to disk.
  """
  @spec write_changelog(String.t()) :: :ok | {:error, :failed_to_write_changelog}
  def write_changelog(content) do
    case File.write(output_path(), content) do
      :ok ->
        :ok

      {:error, _} ->
        {:error, :failed_to_write_changelog}
    end
  end

  # @doc """
  # Prettifies a topic.
  # """
  @spec pretty_topic(String.t()) :: String.t()
  defp pretty_topic(topic) do
    topic
    |> String.replace(["-", "_"], " ")
    |> String.capitalize()
  end
end
