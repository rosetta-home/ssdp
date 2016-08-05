# SSDP

Discover devices on your network that use the [Simple Service Discovery Protocol](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol)

Also supports [Radio Thermostat](http://www.radiothermostat.com/wifi/) which uses Marvell's SSDP implementation. Details are available in the Radio Thermostat [API Documentation](http://assistly-production.s3.amazonaws.com/91626/kb_article_attachments/38350/RTCOAWiFIAPIV1_3_original.pdf?AWSAccessKeyId=AKIAJNSFWOZ6ZS23BMKQ&Expires=1470424460&Signature=cOaMNHy%2BJM4Yfji8a3KBqsu1Ork%3D&response-content-disposition=filename%3D%22RTCOAWiFIAPIV1_3.pdf%22&response-content-type=application%2Fpdf)

## Installation

    1. git clone https://github.com/NationalAssociationOfRealtors/ssdp.git
    2. mix do deps.get, deps.compile
    3. iex -S mix

## Usage

On startup `SSDP.Client` will broadcast a discovery packet over the local network. Compliant devices will respond with a basic header which is parsed and used to gather a more detailed description of the device from an XML file hosted by the device. `SSDP.Client` will notify the event bus, available at `SSDP.Client.Events`, of any devices it finds. Every minute it sends out another discovery broadcast to find any new devices on the network. The event bus will broadcast all devices, not just the new ones it finds. It is up to the developer to handle de-duping the devices broadcast over the event bus. However there is a function `SSDP.Client.devices` that will return a list of all the unique devices on the network.

The events broadcast over the event bus are in the form `{:device, device}` where the device is a Map that consists of the following fields.

    %{
        device: %{
            device_type: 'urn:Belkin:device:insight:1',
            friendly_name: 'WeMo Insight',
            icon_list: [
                %{
                    depth: '100',
                    height: '100',
                    mime_type: 'jpg',
                    url: 'icon.jpg',
                    width: '100'
                }
            ],
            manufacturer: 'Belkin International Inc.',
            manufacturer_url: 'http://www.belkin.com',
            model_description: 'Belkin Insight 1.0',
            model_name: 'Insight',
            model_number: '1.0',
            model_url: 'http://www.belkin.com/plugin/',
            presentation_url: '/pluginpres.html',
            serial_number: nil,
            service_list: [
                %{
                    control_url: '/upnp/control/WiFiSetup1',
                    event_sub_url: '/upnp/event/WiFiSetup1',
                    scpd_url: '/setupservice.xml',
                    service_id: 'urn:Belkin:serviceId:WiFiSetup1',
                    service_type: 'urn:Belkin:service:WiFiSetup:1'
                }
            ],
            udn: 'uuid:Insight-1_0-221350K12000B5',
            upc: nil
        },
        uri: %URI{
            authority: "192.168.1.92",
            fragment: nil,
            host: "192.168.1.92",
            path: nil,
            port: 80,
            query: nil,
            scheme: "http",
            userinfo: nil
        },
        url: nil,
        version: %{
            major: '1',
            minor: '0'
        }
    }

For an example implementation of an event handler see `SSDP.Handler`. To add a handler to the event bus call `SSDP.Client.add_handler(handler)`

    defmodule SSDP.Handler do
        use GenEvent
        require Logger

        def init do
            {:ok, []}
        end

        def handle_event({:device, device} = obj, parent) do
            #do some fun logic here.
            send(parent, obj)
            {:ok, parent}
        end
    end
