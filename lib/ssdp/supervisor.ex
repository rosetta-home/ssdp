defmodule SSDP.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(SSDP.Client, []),
            supervisor(Task.Supervisor, [[name: SSDP.Client.PacketSupervisor]]),
        ]
        supervise(children, strategy: :one_for_one)
    end
end
