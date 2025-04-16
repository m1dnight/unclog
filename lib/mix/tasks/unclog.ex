defmodule Mix.Tasks.Unclog do
  @moduledoc """
  Generate changelog files.
  """
  @shortdoc "Creates changelog files."

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    args
    |> parse_args()
    |> init_scaffolding()
    |> make_release()
    |> generate_changelog()
  end

  @doc """
  Parse the arguments, and fill in the default ones.
  """
  @spec parse_args(Keyword.t()) :: Keyword.t()
  def parse_args(args) do
    {parsed, _, _} =
      OptionParser.parse(args, switches: [init: :boolean, create: :string, generate: :boolean])

    Keyword.validate!(parsed, [:create, init: false, generate: false])
  end

  @doc """
  Initialize scaffolding in the current project.
  """
  @spec init_scaffolding(Keyword.t()) :: Keyword.t()
  def init_scaffolding(opts) do
    if opts[:init] do
      Mix.shell().info("initializing changelogs")
      Unclog.Scaffold.init()
    end

    opts
  end

  @doc """
  Create a new release scaffolding.
  """
  @spec make_release(Keyword.t()) :: Keyword.t()
  def make_release(opts) do
    if Keyword.has_key?(opts, :create) do
      Mix.shell().info("creating a release section")
      release_name = Keyword.get(opts, :create)
      Unclog.Scaffold.make_release(release_name)
    end

    opts
  end

  @doc """
  Generate the changelog file.
  """
  @spec generate_changelog(Keyword.t()) :: Keyword.t()
  def generate_changelog(opts) do
    if opts[:generate] do
      Mix.shell().info("creating changelog")
      Unclog.write_changelog()
    end

    opts
  end
end
