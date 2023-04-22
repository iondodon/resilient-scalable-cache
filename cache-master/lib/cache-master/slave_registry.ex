defmodule Cache.SlaveRegistry do
	use Agent

	require Logger
	@tag_slaves "slaves"
	@tag_replicas "replicas#"

	def start_link(initial_storage) do
		Agent.start_link(fn -> initial_storage end, name: __MODULE__)
	end

	def add_slave(slave_name, slave_socket) do
		Agent.update(__MODULE__, fn registry ->
			slave_hash = Utils.polynomial_rolling_hash(slave_name)

			slaves = Map.get(registry, @tag_slaves, [])

			registry = if not Enum.any?(slaves, fn {name, _hash} -> name == slave_name end) do
				slaves = slaves ++ [{slave_name, slave_hash}]
				# slaves should be sorted by their hash
				slaves = Enum.sort(slaves, fn {_, hash1}, {_, hash2} -> hash1 < hash2 end)
				Map.put(registry, @tag_slaves, slaves)
			else
				registry
			end

			replicas = Map.get(registry, @tag_replicas <> slave_name, [])
			replicas = replicas ++ [slave_socket]

			registry = Map.put(registry, @tag_replicas <> slave_name, replicas)

			registry
		end)
	end

	def get_registry() do
		Agent.get(__MODULE__, fn registry -> registry end)
	end
end
