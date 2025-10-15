defmodule P.Scope do
  alias P.User

  @typedoc "Request scope shared across the application"
  @type t :: %__MODULE__{
          current_user: User.t() | nil
        }

  defstruct current_user: nil

  @doc """
  Builds a new scope.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    %__MODULE__{
      current_user: Keyword.get(opts, :current_user)
    }
  end

  @doc """
  Sets the current user associated with the scope.
  """
  @spec put_current_user(t(), User.t() | nil) :: t()
  def put_current_user(%__MODULE__{} = scope, %User{} = user), do: %{scope | current_user: user}
  def put_current_user(%__MODULE__{} = scope, nil), do: %{scope | current_user: nil}
end
