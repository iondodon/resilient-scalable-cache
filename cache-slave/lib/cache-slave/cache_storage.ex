defmodule Cache.Storage do
    @doc """
    Atomic values are stored as strings
    """
    use Agent
    require Logger

    def start_link(initial_storage) do
        Agent.start_link(fn -> initial_storage end, name: __MODULE__)
    end

    def set(key, value) do
        Agent.update(__MODULE__, fn storage -> Map.put(storage, key, value) end)
    end

    def setnx(key, value) do
        Agent.update(__MODULE__, fn storage -> Map.put_new(storage, key, value) end)
    end

    def get(key) do
        Agent.get(__MODULE__, fn storage -> Map.get(storage, key, nil) end)
    end

    def mget(keys) do
        storage = get_storage()
        Enum.reduce(keys, [], fn key, list ->
            value = Map.get(storage, key)
            list ++ [value]
        end)
    end

    def delete_key(key) do
        storage = get_storage()
        {deleted_value, new_map} = Map.pop(storage, key)
        update_storage(new_map)
        deleted_value
    end

    def delete_keys(keys) do
        Enum.reduce(keys, 0, fn key, deleted ->
            if Map.has_key?(get_storage(), key) do
                {_deleted_value, new_map} = Map.pop(get_storage(), key)
                update_storage(new_map)
                Kernel.inspect(deleted + 1)
            end
        end)
    end

    def increment(key) do
        value = Agent.get(__MODULE__, fn storage -> storage[key] end)
        if value != :nil do
            case Integer.parse(value) do
                {value, _} ->
                    value = Kernel.inspect(value + 1)
                    set(key, value)
                    Kernel.inspect(value)
                :error -> :error
            end
        else
            Agent.update(__MODULE__, fn storage -> Map.put(storage, key, "0") end)
            "0"
        end
    end

    def lpush(key, values) do
        storage = get_storage()

        list = Map.get(storage, key, [])
        if !is_list(list) do
            :not_a_list
        else
            list = Enum.reduce(values, list, fn value, list ->
                [value | list]
            end)

            new_map = Map.put(storage, key, list)
            update_storage(new_map)

            Kernel.inspect(length(list))
        end
    end

    def llen(key) do
        Agent.get(__MODULE__, fn storage ->
            list = Map.get(storage, key, [])
            Kernel.inspect(length(list))
        end)
    end

    def lrem(key, item) do
        storage = get_storage()

        list = Map.get(storage, key)
        if list != :nil do
            new_list = Enum.filter(list, fn value -> value != item end)
            new_map = Map.put(storage, key, new_list)
            update_storage(new_map)
            length(list) - length(new_list)
        else
            0
        end
    end

    def rpoplpush(key1, key2) do
        storage = get_storage()
        list1 = Map.get(storage, key1)
        list2 = Map.get(storage, key2)

        if !is_list(list1) or !is_list(list2) do
            :not_a_list
        else
            if length(list1) == 0 do
                :empy_list
            else
                list1 = Map.get(storage, key1)
                {last, list1_rest} = List.pop_at(list1, -1)
                storage = Map.put(storage, key1, list1_rest)

                list2 = Map.get(storage, key2)
                list2 = [last] ++ list2
                storage = Map.put(storage, key2, list2)

                update_storage(storage)

                last
            end
        end
    end

    def rpop(key) do
        storage = get_storage()
        list = Map.get(storage, key)

        if !is_list(list) do
            :not_a_list
        else
            if length(list) == 0 do
                :empy_list
            else
                list = Map.get(storage, key)
                {last, list_rest} = List.pop_at(list, -1)
                storage = Map.put(storage, key, list_rest)

                update_storage(storage)

                last
            end
        end
    end

    def update_storage(new_storage) do
        Agent.update(__MODULE__, fn _storage -> new_storage end)
    end

    def get_storage() do
        Agent.get(__MODULE__, fn storage -> storage end)
    end
end
