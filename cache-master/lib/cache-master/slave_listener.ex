defmodule Cache.SlaveListener do
	use Task, restart: :permanent
	require Logger
	alias Cache.SlaveRegistry

	@port_for_slave Application.get_env(:cache_master, :port_for_slave, 6667)
	@recv_length 0
	@delay 1000

	def start_link(_args) do
		Task.start_link(__MODULE__, :run, [])
	end

	def run() do
		listen(@port_for_slave)
	end

	def listen(port) do
		opts = [:binary, packet: :line, active: false, reuseaddr: true]
		{:ok, socket} = :gen_tcp.listen(port, opts)
		Logger.info "\n Listening slaves on port #{port}"
		loop_acceptor(socket)
	end

	defp loop_acceptor(socket) do
		{:ok, slave} = :gen_tcp.accept(socket)
		Logger.info("\n New slave connected #{Kernel.inspect slave}")

		Task.async(fn -> register_slave(slave) end)

		loop_acceptor(socket)
	end

	defp get_replica_state(slave_name) do
		slave_registry = SlaveRegistry.get_registry()
		replicas = Map.get(slave_registry, "replicas#" <> slave_name, [])
		case List.first(replicas) do
			:nil -> {:ok, "(map) {}\n"}
			first_replica ->
				:ok = :gen_tcp.send(first_replica, "GETSTATE\n")
				:gen_tcp.recv(first_replica, @recv_length)
		end
	end

	defp register_slave(slave) do
		{:ok, slave_name} = :gen_tcp.recv(slave, @recv_length)
		slave_name = String.replace(slave_name, "\n", "")

		# send replica state
		:timer.sleep(@delay)
		IO.inspect("Sending initial state to the new replica")
		{:ok, io_state} = get_replica_state(slave_name)
		:ok = :gen_tcp.send(slave, io_state)

		SlaveRegistry.add_slave(slave_name, slave)
		Logger.info("\n Slave #{Kernel.inspect(slave)} added")
		IO.inspect(SlaveRegistry.get_registry())
	end
end
