defmodule Cache.CommandListener do
    require Logger
    @data_length 0

    def serve(client_socket) do
        {:ok, io_command} = read_from_client(client_socket)
        {:ok, command} = Cache.Command.parse(io_command)
        result = Cache.Command.run(io_command, command)
        send_to_client(client_socket, result)

        serve(client_socket)
    end

    defp read_from_client(client_socket) do
        :gen_tcp.recv(client_socket, @data_length)
    end

    defp send_to_client(client_socket, result) do
        :gen_tcp.send(client_socket, "#{result} \r\n")
    end
end
