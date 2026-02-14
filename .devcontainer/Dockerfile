FROM hexpm/elixir:1.18.2-erlang-27.2-debian-bookworm-20250113-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    inotify-tools \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /workspace

RUN mkdir -p /workspace/_build /workspace/deps
