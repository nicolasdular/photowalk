defmodule Thexstack.Accounts do
  use Ash.Domain, otp_app: :thexstack, extensions: [AshTypescript.Rpc]

  typescript_rpc do
    resource Thexstack.Accounts.User do
      rpc_action(:register_with_password, :register_with_password)
    end
  end

  resources do
    resource Thexstack.Accounts.Token
    resource Thexstack.Accounts.User
  end
end
