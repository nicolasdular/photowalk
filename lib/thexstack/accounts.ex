defmodule Thexstack.Accounts do
  use Ash.Domain, otp_app: :thexstack, extensions: [AshTypescript.Rpc]

  typescript_rpc do
    resource Thexstack.Accounts.User do
      rpc_action(:request_magic_link, :request_magic_link)
      rpc_action(:current_user, :current_user)
    end
  end

  resources do
    resource Thexstack.Accounts.Token
    resource Thexstack.Accounts.User
  end
end
