# Thexstack

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Deployment

### Dokku

1. Initial setup

```sh
dokku apps:create thexstack
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git
dokku postgres:create thexstackdb
dokku postgres:link thexstackdb thexstack
```

2. ENV variables

```sh
mix phx.gen.secret # => generates a secret key
```

```sh
dokku config:set thexstack ENV=prod PHX_HOST=yourdomain.com EMAIL_DOMAIN=youremaildomain.com SECRET_KEY_BASE=generated-key1 TOKEN_SIGNING_SECRET=genereated-key-2 RESEND_API_KEY=re_123123
```

3. Connect repo

```
git remote add dokku dokku@dokku.nicnac.party:thexstack

git push dokku main
```
