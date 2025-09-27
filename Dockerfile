# syntax=docker/dockerfile:1

# ---- Assets stage (Bun + Vite) ----
FROM oven/bun:1 AS assets
WORKDIR /app

# Install JS deps with good caching
COPY assets/package.json assets/bun.lock ./assets/
RUN cd assets && bun install --frozen-lockfile

# Copy the rest of the assets and build
COPY assets ./assets
RUN cd assets && bun vite build


# ---- Elixir build stage (mix release) ----
ARG ELIXIR_IMAGE_TAG=1.18.3-erlang-27.3.4-debian-buster-20240612
FROM hexpm/elixir:${ELIXIR_IMAGE_TAG} AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod
WORKDIR /app

# Elixir tooling
RUN mix local.hex --force && mix local.rebar --force

# Cache deps
COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only prod && mix deps.compile

# Copy application source
COPY lib ./lib
COPY rel ./rel
COPY priv ./priv

# Bring in built assets
COPY --from=assets /app/priv/static ./priv/static

# Compile and build the release
RUN mix compile && mix release


# ---- Runtime stage ----
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
      openssl libstdc++6 ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
WORKDIR /app

# Use a non-root user for safety
RUN useradd --create-home appuser

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/thexstack ./thexstack

RUN chown -R appuser:appuser /app
USER appuser

ENV PHX_SERVER=true MIX_ENV=prod
EXPOSE 4000

CMD ["./thexstack/bin/thexstack", "start"]

