defmodule Unclog.Scaffold do
  @moduledoc """
  Functions to create scaffolding.
  """

  @doc """
  Initialize the scaffolding to hold the changelogs.

  Creates the following directory structure.

  ```
  .changelogs
  └── preamble.md
  ```
  """
  @spec init() :: :ok | {:error, :failed_to_create_scaffold}
  def init do
    path = Application.get_env(:unclog, :root, ".changelogs")

    # default paths
    preamble_path = Path.join(path, "preamble.md")

    # default content
    preamble_content = "# Changelog"

    with :ok <- File.mkdir_p(path),
         :ok <- write_if_missing(preamble_path, preamble_content) do
      :ok
    else
      {:error, _} ->
        {:error, :failed_to_create_scaffold}
    end
  end

  defp write_if_missing(path, content) do
    if File.exists?(path), do: :ok, else: File.write(path, content)
  end

  @doc """
  Initialize the scaffolding for a new release.

  Creates the following directory structure.

  ```
  .changelogs
  ├── release_name_here
  │   ├── breaking_changes
  │   │   └── change.md
  │   ├── bug-fixes
  │   │   └── change.md
  │   ├── features
  │   │   └── change.md
  │   └── summary.md
  └── preamble.md
  ```
  """
  @spec make_release() :: :ok | {:error, :failed_to_create_release}
  def make_release(name \\ "release_name_here") do
    path = Application.get_env(:unclog, :root, ".changelogs")

    release_path = Path.join(path, name)
    breaking_path = Path.join(release_path, "breaking_changes")
    features_path = Path.join(release_path, "features")
    bugfix_path = Path.join(release_path, "bug-fixes")

    # default content
    summary_content = Calendar.strftime(DateTime.utc_now(), "%A, %B %d, %Y")

    with :ok <- File.mkdir(release_path),
         # create summary file and initial content
         :ok <- File.write(Path.join(release_path, "summary.md"), summary_content),
         # create breaking changes files
         :ok <- File.mkdir(breaking_path),
         :ok <- File.touch(Path.join(breaking_path, "change.md")),
         # create features changes files
         :ok <- File.mkdir(features_path),
         :ok <- File.touch(Path.join(features_path, "change.md")),
         # create bugfix changes files
         :ok <- File.mkdir(bugfix_path),
         :ok <- File.touch(Path.join(bugfix_path, "change.md")) do
      :ok
    else
      {:error, _e} ->
        {:error, :failed_to_create_release}
    end
  end
end
