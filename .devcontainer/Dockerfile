FROM hexpm/elixir:1.18.4-erlang-28.0.1-ubuntu-noble-20250619

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git inotify-tools vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
