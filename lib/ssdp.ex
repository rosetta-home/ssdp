defmodule SSDP do
    use Application
    require Logger

    def start(_type, _args) do
        SSDP.Supervisor.start_link
    end
end
