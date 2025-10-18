defmodule PWeb.API.Presenter do
  @spec present(module(), term(), term()) :: term()
  def present(module, data, opts \\ [])

  def present(module, data, opts) when is_list(data) do
    data
    |> maybe_preload(module, opts)
    |> Enum.map(&module.build(&1, opts))
  end

  def present(module, data, opts) do
    data
    |> maybe_preload(module, opts)
    |> module.build(opts)
  end

  defp maybe_preload(data, module, opts) do
    case module.preload(opts) do
      nil -> data
      [] -> data
      preloads -> P.Repo.preload(data, preloads)
    end
  end
end
