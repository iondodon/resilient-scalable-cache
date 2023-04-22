defmodule Cache.Command do
    require Logger
    alias Cache.SlaveRegistry

    @recv_length 0
    @tag_replicas "replicas#"

    def parse(line) do
        case String.split(line) do
            ["SET", key, value] -> {:ok, {:set, key, value}}
            ["SETNX", key, value] -> {:ok, {:setnx, key, value}}
            ["GET", key] -> {:ok, {:get, key}}
            ["MGET" | keys] -> {:ok, {:mget, keys}}
            ["DEL", key] -> {:ok, {:del, key}}
            ["DEL" | keys] -> {:ok, {:del, keys}}
            ["INCR", key] -> {:ok, {:incr, key}}
            ["LPUSH", key | values] -> {:ok, {:lpush, key, values}}
            ["RPOP", key] -> {:ok, {:rpop, key}}
            ["LLEN", key] -> {:ok, {:llen, key}}
            ["LREM", key, value] -> {:ok, {:lrem, key, value}}
            ["RPOPLPUSH", key1, key2] -> {:ok, {:rpoplpush, key1, key2}}
            ["EXPIRE", key, sec] -> {:ok, {:expire, key, sec}}
            ["TTL", key] -> {:ok, {:ttl, key}}
            _ -> {:error, :unknown_command}
          end
    end

    # Command execution on slave
    def run(io_command, command)


    def run(io_command, {:set, key, value}) do
        Logger.info("\n SET #{key} to #{value}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:setnx, key, value}) do
        Logger.info("\n SET  #{key} to #{value}, if not exists")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end

    #on slave
    def run(io_command, {:get, key}) do
        Logger.info("\n GET #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(_io_command, {:mget, keys}) do
        keys_str = Enum.reduce(keys, "", fn key, keys_str -> keys_str <> key <> " " end)
        Logger.info("\n MGET #{keys_str}")

        values = Enum.reduce(keys, [], fn key, list ->
            key_hash = hash_key(key)
            response = run_on_slave("GET #{key} \n", key_hash)
            value = Utils.parse_slave_response(response)
            list ++ [value]
        end)

        IO.inspect(values)
        Enum.reduce(values, "", fn value, str ->
            str <> Kernel.inspect(value) <> " "
        end)
    end


    # Deletes multiple keys
    def run(_io_command, {:del, keys}) when is_list(keys) do
        keys_str = Enum.reduce(keys, "", fn key, keys_str -> keys_str <> key <> " " end)
        Logger.info("\n DELETE #{keys_str}")

        Enum.each(keys, fn key ->
            key_hash = hash_key(key)
            response = run_on_slave("DEL #{key} \n", key_hash)
            Logger.info("Response from slave: #{response}")
        end)

        "deleted"
    end


    def run(io_command, {:del, key}) do
        Logger.info("\n DELETE #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:incr, key}) do
        Logger.info("\n INCR #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:lpush, key, values}) do
        Logger.info("\n LPUSH into #{key} values #{Kernel.inspect(values)}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:rpop, key}) do
        Logger.info("\n RPOP #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:llen, key}) do
        Logger.info("\n LLEN #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:lrem, key, value}) do
        Logger.info("\n LREM  #{value} in #{key}")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(_io_command, {:rpoplpush, key1, key2}) do
        Logger.info("\n RPOPLPUSH #{key1} #{key2}")

        key_hash = hash_key(key1)
        rpop_result = run_on_slave("RPOP #{key1} \n", key_hash)
        poped = Utils.parse_slave_response(rpop_result)
        IO.inspect("\n RPOP result: #{poped}")

        key_hash = hash_key(key2)
        lpush_result = run_on_slave("LPUSH #{key2} #{poped} \n", key_hash)
        IO.inspect("\n LPUSH result: #{lpush_result}")

        rpop_result
    end


    def run(io_command, {:ttl, key}) do
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    def run(io_command, {:expire, key, sec}) do
        Logger.info("EXPIRE #{key} in #{sec} seconds")
        key_hash = hash_key(key)
        run_on_slave(io_command, key_hash)
    end


    defp hash_key(key) do
        key_hash = Utils.polynomial_rolling_hash(key)
        Logger.info("Key hash: #{key_hash}")
        key_hash
    end


    defp run_on_slave(io_command, key_hash) do
        registry = SlaveRegistry.get_registry()
        slaves = Map.get(registry, "slaves", [])

        if Enum.empty?(slaves) do
            "error: no slave to run on"
        end

        # Distributed Hashing - circle
        {slave_name, slave_hash} = find_slave_to_use(slaves, key_hash)

        [first_replica_socket | rest_replicas] = Map.get(registry, @tag_replicas <> slave_name)


        Logger.info("EXECUTE #{io_command} on slave #{slave_name} with hash #{slave_hash}")
        :ok = :gen_tcp.send(first_replica_socket, io_command)

        # update the rest of the replicas
        Task.async(fn -> update_replicas(io_command, rest_replicas) end)

        {:ok, response_from_slave} = :gen_tcp.recv(first_replica_socket, @recv_length)
        Logger.info("Response from slave: #{response_from_slave}")
        response_from_slave
    end


    defp update_replicas(io_command, replicas) do
        Enum.each(replicas, fn replica_slave_socket ->
            :gen_tcp.send(replica_slave_socket, io_command)
            _response = :gen_tcp.recv(replica_slave_socket, @recv_length)
        end)
    end


    # Distributed Hashing - circle - find slave candidate
    defp find_slave_to_use(slaves, key_hash) when is_list(slaves) do
        Enum.find(slaves, List.first(slaves), fn {slave_name, slave_hash} ->
            if slave_hash >= key_hash do
                {slave_name, slave_hash}
            end
        end)
    end
end
