defmodule P.Scope do
  alias P.User

  @type name :: :browser | :api | :public_api | atom()

  @typedoc "Request scope shared across the application"
  @type t :: %__MODULE__{
          name: name(),
          current_user: User.t() | nil
        }

  @enforce_keys [:name]
  defstruct name: :default, current_user: nil

  @doc """
  Builds a new scope.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    name = Keyword.fetch!(opts, :name)

    %__MODULE__{
      name: name,
      current_user: Keyword.get(opts, :current_user)
    }
  end

  @doc """
  Sets the current user associated with the scope.
  """
  @spec put_current_user(t(), User.t() | nil) :: t()
  def put_current_user(%__MODULE__{} = scope, %User{} = user), do: %{scope | current_user: user}
  def put_current_user(%__MODULE__{} = scope, nil), do: %{scope | current_user: nil}

  @doc """
  Changes the scope name.
  """
  @spec with_name(t(), name()) :: t()
  def with_name(%__MODULE__{} = scope, name) when is_atom(name) do
    %{scope | name: name}
  end
end
