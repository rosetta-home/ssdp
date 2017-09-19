defmodule SSDP.Parser do
    require Logger
    import SweetXml

    def parse(text) do
        text
        |> xpath(
            ~x"//root",
            version: [
                ~x"./specVersion",
                major: ~x"./major/text()",
                minor: ~x"./minor/text()",
            ],
            url: ~x"./URLBase/text()",
            uri: ~x"./URLBase/text()",
            device: [
                ~x"./device",
                device_type: ~x"./deviceType/text()",
                friendly_name: ~x"./friendlyName/text()",
                manufacturer: ~x"./manufacturer/text()",
                manufacturer_url: ~x"./manufacturerURL/text()",
                model_description: ~x"./modelDescription/text()",
                model_name: ~x"./modelName/text()",
                model_number: ~x"./modelNumber/text()",
                model_url: ~x"./modelURL/text()",
                serial_number: ~x"./SerialNumber/text()",
                udn: ~x"./UDN/text()",
                upc: ~x"./upc/text()",
                presentation_url: ~x"./presentationURL/text()",
                icon_list: [
                    ~x"./iconList/icon"l,
                    mime_type: ~x"./mimetype/text()",
                    height: ~x"./height/text()",
                    width: ~x"./width/text()",
                    depth: ~x"./depth/text()",
                    url: ~x"./url/text()",
                ],
                service_list: [
                    ~x"./serviceList/service"l,
                    service_type: ~x"./serviceType/text()",
                    service_id: ~x"./serviceId/text()",
                    control_url: ~x"./controlURL/text()",
                    event_sub_url: ~x"./eventSubURL/text()",
                    scpd_url: ~x"./SCPDURL/text()",
                ]
            ]
        )
    end
end
