import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/photowalk start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :photowalk, PWeb.Endpoint, server: true
end

r2_bucket =
  case System.get_env("R2_BUCKET") do
    "" -> nil
    value -> value
  end

if r2_bucket do
  account_id =
    System.get_env("R2_ACCOUNT_ID") ||
      raise "Missing environment variable `R2_ACCOUNT_ID`!"

  access_key_id =
    System.get_env("R2_ACCESS_KEY_ID") ||
      raise "Missing environment variable `R2_ACCESS_KEY_ID`!"

  secret_access_key =
    System.get_env("R2_SECRET_ACCESS_KEY") ||
      raise "Missing environment variable `R2_SECRET_ACCESS_KEY`!"

  region = "auto"

  public_host =
    case System.get_env("R2_PUBLIC_HOST") do
      "" -> "https://#{account_id}.r2.cloudflarestorage.com/#{r2_bucket}"
      nil -> "https://#{account_id}.r2.cloudflarestorage.com/#{r2_bucket}"
      value -> value
    end

  config :waffle,
    storage: Waffle.Storage.S3,
    storage_dir_prefix: nil,
    bucket: r2_bucket,
    asset_host: public_host

  config :ex_aws,
    access_key_id: access_key_id,
    secret_access_key: secret_access_key,
    region: region,
    s3: [
      scheme: "https://",
      host: "#{account_id}.r2.cloudflarestorage.com",
      region: region
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :photowalk, P.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")
  url_scheme = System.get_env("PHX_URL_SCHEME") || "https"
  url_port = String.to_integer(System.get_env("PHX_URL_PORT") || "443")

  config :photowalk, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :photowalk, PWeb.Endpoint,
    url: [host: host, port: url_port, scheme: url_scheme],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    email_host: System.get_env("EMAIL_HOST") || host,
    secret_key_base: secret_key_base,
    cache_static_manifest_latest: PhoenixVite.cache_static_manifest_latest(:photowalk)

  config :photowalk,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!")

  config :photowalk, P.Mailer,
    api_key:
      System.get_env("RESEND_API_KEY") ||
        raise("Missing environment variable `RESEND_API_KEY`!")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :photowalk, PWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :photowalk, PWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :photowalk, P.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
