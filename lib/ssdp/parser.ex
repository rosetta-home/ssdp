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
                    ~x"./iconList"l,
                    mime_type: ~x"./icon/mimetype/text()",
                    height: ~x"./icon/height/text()",
                    width: ~x"./icon/width/text()",
                    depth: ~x"./icon/depth/text()",
                    url: ~x"./icon/url/text()",
                ],
                service_list: [
                    ~x"./serviceList"l,
                    service_type: ~x"./service/serviceType/text()",
                    service_id: ~x"./service/serviceId/text()",
                    control_url: ~x"./service/controlURL/text()",
                    event_sub_url: ~x"./service/eventSubURL/text()",
                    scpd_url: ~x"./service/SCPDURL/text()",
                ]

            ]
        )
    end
end
