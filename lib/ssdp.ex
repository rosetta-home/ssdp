defmodule SSDP do
  use Application
  require Logger

  def start(_type, _args) do
    SSDP.Supervisor.start_link
  end

  def register do
    SSDP.Client |> GenServer.call(:register)
  end

  def dispatch(type, event) do
    Logger.debug "Dispatching: #{inspect type} - #{inspect event}"
    case Registry.lookup(SSDP.Registry, type) do
      [] -> Logger.debug "No Registrations for #{inspect type}"
      _ ->
        Registry.dispatch(SSDP.Registry, type, fn entries ->
          for {_module, pid} <- entries, do: send(pid, event)
        end)
    end
    Logger.debug "Dispatched: #{inspect event}"
    event
  end
end
