defmodule Cache.LiveManager do
    use Task, restart: :permanent
    require Logger
    alias Cache.Storage
    alias Cache.Storage.Extra
    @delay_interval 1000 # millis

    def start_link(_args) do
      Task.start_link(__MODULE__, :run, [])
    end
  
    def run() do
        loop_manage_cache()
    end

    def loop_manage_cache() do
        clean_expired_keys()
        :timer.sleep(@delay_interval)
        loop_manage_cache()
    end

    defp clean_expired_keys() do
        ttls = Extra.get_ttls()
        Enum.each(Map.keys(ttls), fn ttlkey -> 
            if System.os_time(:second) >= ttls[ttlkey] do
                "ttl#" <> key = ttlkey
                Storage.delete_key(key)
                Extra.delete_ttl(ttlkey)
                Logger.info("Key #{key} expired")
            end
        end)
    end
end