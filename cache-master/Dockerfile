FROM elixir:1.12.2

COPY ./ /cache-master
WORKDIR /cache-master

#RUN apt update && apt install erlang-wx

RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get

CMD iex -S mix

EXPOSE 6666 6667