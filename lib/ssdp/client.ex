defmodule SSDP.Client do
    use GenServer
    require Logger
    import SweetXml

    @port 1900
    @multicast_group {239,255,255,250}

    defmodule State do
        defstruct udp: nil,
            events: nil,
            devices: [],
            handlers: [],
            port: nil
    end

    def discover_messages do
        ["M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: upnp:rootdevice\r\n\r\n",
        "TYPE: WM-DISCOVER\r\nVERSION: 1.0\r\n\r\nservices:com.marvell.wm.system*\r\n\r\n",]
    end

    def start_link do
        GenServer.start_link(__MODULE__, @port, name: __MODULE__)
    end

    def discover do
        GenServer.call(__MODULE__, :discover)
    end

    def devices do
        GenServer.call(__MODULE__, :devices)
    end

    def add_handler(handler) do
        GenServer.call(__MODULE__, {:handler, handler})
    end

    def start do
      GenServer.call(__MODULE__, :start)
    end

    def init(port) do
        {:ok, events} = GenEvent.start_link([{:name, SSDP.Client.Events}])
        GenEvent.add_mon_handler(events, SSDP.Handler, self)
        {:ok, %State{:events => events, :handlers => [{SSDP.Handler, self}], :port => port}}
    end

    def handle_call(:start, _from, state) do
        udp_options = [
            :binary,
            add_membership:  { @multicast_group, {0,0,0,0} },
            multicast_if:    {0,0,0,0},
            multicast_loop:  false,
            multicast_ttl:   2,
            reuseaddr:       true
        ]
        {:ok, udp} = :gen_udp.open(state.port, udp_options)
        Process.send_after(self(), :discover, 0)
        {:reply, :ok, %State{state | udp: udp}}
    end

    def handle_call({:handler, handler}, {pid, _} = from, state) do
        GenEvent.add_mon_handler(state.events, handler, pid)
        {:reply, :ok, %{state | :handlers => [{handler, pid} | state.handlers]}}
    end

    def handle_call(:devices, _from, state) do
        {:reply, state.devices, state}
    end

    def handle_info({:gen_event_EXIT, handler, reason}, state) do
        Enum.each(state.handlers, fn(h) ->
            GenEvent.add_mon_handler(state.events, elem(h, 0), elem(h, 1))
        end)
        {:noreply, state}
    end

    def handle_info(:discover, state) do
        Enum.each(discover_messages, fn(m) ->
            Logger.debug "Sending Discovery: #{m}"
            :gen_udp.send(state.udp, @multicast_group, @port, m)
        end)
        Process.send_after(self, :discover, 60000)
        {:noreply, state}
    end

    def handle_info({:udp, _s, ip, port, <<"M-SEARCH * HTTP/1.1", rest :: binary>>}, state) do
        {:noreply, state}
    end

    def handle_info({:udp, _s, ip, port, <<"HTTP/1.1 200 OK", rest :: binary>>}, state) do
        case parse_xml(rest, ip) do
            {:ok, obj} -> GenEvent.notify(state.events, {:device, obj})
            {:error, reason} -> Logger.error("#{inspect reason}")
        end
        {:noreply, state}
    end

    def handle_info({:udp, _s, ip, port, <<"NOTIFY * HTTP/1.1", rest :: binary>>}, state) do
        case parse_xml(rest, ip) do
            {:ok, obj} -> GenEvent.notify(state.events, {:device, obj})
            {:error, reason} -> Logger.error("ERROR: #{reason}")
        end
        {:noreply, state}
    end

    def handle_info({:udp, _s, ip, port, <<"TYPE: WM-NOTIFY", rest:: binary>>}, state) do
        case parse_json(rest, ip) do
            {:ok, obj} -> GenEvent.notify(state.events, {:device, obj})
            {:error, reason} -> Logger.error("ERROR: #{reason}")
        end
        {:noreply, state}
    end

    def handle_info({:device, device}, state) do
        new_state =
            cond do
                Enum.any?(state.devices, fn(dev) -> dev.device.udn == device.device.udn end) ->
                    %State{state | :devices => Enum.map(state.devices, fn(d) ->
                        cond do
                            device.device.udn == d.device.udn -> device
                            true -> d
                        end
                    end)}
                true ->
                    Logger.debug "New Device #{device.device.friendly_name}: #{device.device.udn} #{inspect device}"
                    %State{state | :devices => [device | state.devices]}
            end
        {:noreply, new_state}
    end

    def handle_info({:udp, _s, ip, port, rest}, state), do: {:noreply, state}
    def handle_info({:udp_passive, _}, state), do: {:noreply, state}

    def parse_keys(rest) do
        raw_params = String.split(rest, ["\r\n", "\n"])
        mapped_params = Enum.map raw_params, fn(x) ->
            case String.split(x, ":", parts: 2) do
                [k, v] -> {String.to_atom(String.downcase(k)), String.strip(v)}
                _ -> nil
            end
        end
        Enum.reject mapped_params, &(&1 == nil)
    end

    def parse_json(rest, ip) do
        resp = parse_keys(rest)
        ip = :inet_parse.ntoa(ip)
        url = "http://#{ip}"
        case HTTPoison.get(Dict.get(resp, :location), [], hackney: [:insecure]) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                obj = Poison.Parser.parse!(body)
                obj = %{
                    :version => %{
                        :major => obj["api_version"],
                        :minor => 0
                    },
                    :uri => URI.parse(url),
                    :url => url,
                    :device => %{
                        :device_type => Dict.get(resp, :service),
                        :friendly_name => "Radio Thermostat",
                        :manufacturer => "Radio Thermostat",
                        :serial_number => obj["uuid"],
                        :icon_list => [],
                        :service_list => [],
                        :udn => obj["uuid"],
                    }
                }
                {:ok, obj}
            {:ok, %HTTPoison.Response{status_code: 404}} ->
                {:error, "Not Found"}
            {:ok, %HTTPoison.Response{body: body}} ->
                {:error, body}
            {:error, %HTTPoison.Error{reason: reason}} ->
                {:error, reason}
        end
    end

    def parse_xml(rest, ip) do
        resp = parse_keys(rest)
        ip = :inet_parse.ntoa(ip)
        url = "http://#{ip}"
        case HTTPoison.get(Dict.get(resp, :location), [], hackney: [:insecure]) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                obj = body |> SSDP.Parser.parse
                obj =
                    cond do
                        obj.url == nil -> %{obj | :uri => URI.parse(url)}
                        true -> %{obj | :uri => URI.parse(to_string(obj.url))}
                    end
                {:ok, obj}
            {:ok, %HTTPoison.Response{status_code: 404}} ->
                {:error, "Not Found"}
            {:ok, %HTTPoison.Response{body: body}} ->
                {:error, body}
            {:error, %HTTPoison.Error{reason: reason}} ->
                {:error, reason}
        end
    end
end
