defmodule Cache.Connection do
	alias Cache.Storage
	require Logger
	require IEx

	@master_ip Application.get_env(:cache_slave, :master_ip, 'cache-master')
	@master_port Application.get_env(:cache_slave, :master_port, 6667)

	@delay 1000
	@recv_length 0

	def connect() do
		opts = [:binary, :inet, active: false, packet: :line]
		{:ok, master_socket} = :gen_tcp.connect(@master_ip, @master_port, opts)
		Logger.info("\n Connected to master")

		#IEx.pry

		:timer.sleep(@delay)

		# "\n" is a MUST, it won't work without it, it won't be received
		:ok = :gen_tcp.send(master_socket, System.get_env("SLAVE_NAME") <> "\n")

		{:ok, io_data} = :gen_tcp.recv(master_socket, @recv_length)
		io_data = String.replace(io_data, "\n", "")
		"(map) " <> state = io_data
		{:ok, state} = Poison.decode(state)
		Logger.info("\n Received initial state from siblings")
		Storage.update_storage(state)
		IO.inspect(state)

		Logger.info("\n Successfully registered to master")

		{:ok, _pid} = Task.Supervisor.start_child(
			CommandListener.Supervisor,
			fn -> Cache.CommandListener.serve(master_socket) end,
			[restart: :permanent]
		)
	end

	def child_spec(_opts) do
		%{
		 	id: __MODULE__,
		 	start: {__MODULE__, :connect, []},
			type: :worker,
			restart: :permanent
		}
	end
end
