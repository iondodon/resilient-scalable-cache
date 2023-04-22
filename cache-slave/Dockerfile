FROM elixir:1.12.2

COPY ./ /cache-slave
WORKDIR /cache-slave

#RUN apt update && apt install erlang-wx

RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get

CMD iex -S mix