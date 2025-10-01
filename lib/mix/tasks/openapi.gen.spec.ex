defmodule Mix.Tasks.Openapi.Gen.Spec do
  @moduledoc """
  Generates the OpenAPI specification JSON file.

  ## Usage

      mix openapi.gen.spec

  This task generates the OpenAPI spec and writes it to priv/static/openapi.json
  """
  use Mix.Task

  @shortdoc "Generates OpenAPI specification JSON file"

  @impl Mix.Task
  def run(_args) do
    # Load the application code without starting the full application
    Mix.Task.run("compile")

    spec = ThexstackWeb.ApiSpec.spec()
    json = Jason.encode!(spec, pretty: true)

    output_path = Path.join(["priv", "static", "openapi.json"])
    output_dir = Path.dirname(output_path)

    File.mkdir_p!(output_dir)
    File.write!(output_path, json)

    Mix.shell().info("Generated OpenAPI spec at #{output_path}")
  end
end
