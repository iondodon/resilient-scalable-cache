defmodule Cache.Storage.Extra do
    use Agent
    require Logger

    def start_link(initial_storage) do
        Agent.start_link(fn -> initial_storage end, name: __MODULE__)
    end

    def set_key_ttl(key, ttl) do
        ttls = get_ttls()
        Agent.update(__MODULE__, fn extra_storage ->
            Map.put(extra_storage, "ttls", Map.put(ttls, key, ttl))
        end)
    end

    def get_ttls() do
        Agent.get(__MODULE__, fn extra_storage -> Map.get(extra_storage, "ttls", %{}) end)
    end

    def get_ttl(ttlkey) do
        Agent.get(__MODULE__, fn extra_storage ->
            extra_storage["ttls"][ttlkey]
        end)
    end

    def delete_ttl(ttlkey) do
        Agent.update(__MODULE__, fn extra_storage ->
            ttls = extra_storage["ttls"]
            {_deleted_ttl, new_ttl_map} = Map.pop(ttls, ttlkey)
            Map.put(extra_storage, "ttls", new_ttl_map)
        end)
    end
end
