defmodule CacheSlave do
  use Application

  def start(_type, _args) do
    Cache.BaseSupervisor.start_link()
  end
end
