FROM hexpm/elixir:1.18.4-erlang-28.0.1-ubuntu-noble-20250619

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential curl git inotify-tools vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-x86_64-unknown-linux-musl.tar.gz | tar zxv \
    && mv mcp-proxy /usr/local/bin/
