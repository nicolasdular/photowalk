defmodule PWeb.API.Resource do
  @moduledoc """
  Behaviour implemented by API resource serializers.

  Resources declare which associations they depend on via `c:preload/1` and
  describe how to turn a fully-loaded struct into a map via `c:serialize/2`.
  """

  @callback preload(keyword()) :: term() | nil
  @callback build(struct(), keyword()) :: map()
  @callback build(struct()) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour PWeb.API.Resource

      @impl PWeb.API.Resource
      def preload(_opts), do: []

      defoverridable preload: 1
    end
  end
end
