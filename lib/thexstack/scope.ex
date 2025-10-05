defmodule Thexstack.Scope do
  @moduledoc """
  Represents the request scope that must be provided to all domain APIs.

  The scope captures the context in which a request is processed, including
  the pipeline name (browser, api, etc), the authenticated user (if any), and
  miscellaneous metadata. Domains can use the scope to make authorization
  decisions or tailor behaviour based on the request environment.
  """

  alias Thexstack.Accounts.User

  @typedoc "Identifies where the scope originated from"
  @type name :: :browser | :api | :public_api | atom()

  @typedoc "Arbitrary metadata collected for the scope"
  @type metadata :: %{optional(atom()) => term()}

  @typedoc "Request scope shared across the application"
  @type t :: %__MODULE__{
          name: name(),
          current_user: User.t() | nil,
          metadata: metadata()
        }

  @enforce_keys [:name]
  defstruct name: :default, current_user: nil, metadata: %{}

  @doc """
  Builds a new scope.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    name = Keyword.fetch!(opts, :name)

    %__MODULE__{
      name: name,
      current_user: Keyword.get(opts, :current_user),
      metadata: Map.new(Keyword.get(opts, :metadata, %{}))
    }
  end

  @doc """
  Sets the current user associated with the scope.
  """
  @spec put_current_user(t(), User.t() | nil) :: t()
  def put_current_user(%__MODULE__{} = scope, %User{} = user), do: %{scope | current_user: user}
  def put_current_user(%__MODULE__{} = scope, nil), do: %{scope | current_user: nil}

  @doc """
  Updates the metadata map by merging the provided values.
  """
  @spec merge_metadata(t(), metadata()) :: t()
  def merge_metadata(%__MODULE__{} = scope, metadata) when is_map(metadata) do
    %{scope | metadata: Map.merge(scope.metadata, metadata)}
  end

  @doc """
  Retrieves a metadata value.
  """
  @spec get_metadata(t(), atom(), term()) :: term()
  def get_metadata(%__MODULE__{} = scope, key, default \\ nil) when is_atom(key) do
    Map.get(scope.metadata, key, default)
  end

  @doc """
  Changes the scope name.
  """
  @spec with_name(t(), name()) :: t()
  def with_name(%__MODULE__{} = scope, name) when is_atom(name) do
    %{scope | name: name}
  end
end
