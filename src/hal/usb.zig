const std = @import("std");
const assert = std.debug.assert;

pub const DescriptorType = enum(u8) {
    device = 0x01,
    config = 0x02,
    string = 0x03,
    interface = 0x04,
    endpoint = 0x05,
    _,
};

pub const SetupPacket = packed struct {
    pub const RequestType = packed struct {
        data_phase_xfer_dir: enum(u1) {
            host_to_device,
            device_to_host,
        },
        @"type": enum(u2) {
            standard,
            class,
            vendor,
            reserved,
        },
        recipient: enum(u5) {
            device,
            interface,
            endpoint,
            other,
            _,
        },
    };

    pub const Request = enum(u8) {
        // eight standard device requests
        get_status = 0x00,
        clear_feature = 0x01,
        set_feature = 0x03,
        set_address = 0x05,
        get_descriptor = 0x06,
        set_descriptor = 0x07,
        get_configuration = 0x08,
        set_configuration = 0x09,
        get_interface = 0x0a,
        set_interface = 0x11,
        synch_frame = 0x12,
        _,
    };

    comptime {
        assert(8 == @bitSizeOf(RequestType));
    }

    request_type: RequestType,
    request: u8,
    value: u16,
    index: u16,
    length: u16,
};

pub const Descriptor = packed struct {
    length: u8,
    descriptor_type: DescriptorType,
};

pub const DeviceDescriptor = packed struct {
    length: u8 = @sizeOf(DeviceDescriptor),
    descriptor_type: DescriptorType = .device,
    bcd_usb: u16,
    device_class: u8,
    device_subclass: u8,
    device_protocol: u8,
    max_packet_size0: u8,
    vendor_id: u16,
    product_id: u16,
    bcd_device: u16,
    manufacturer: u8,
    product: u8,
    serial_number: u8,
    num_configurations: u8,
};

pub const ConfigurationDescriptor = packed struct {
    length: u8 = @sizeOf(ConfigurationDescriptor),
    descriptor_type: DescriptorType = .config,
    total_length: u16,
    num_interfaces: u8,
    configuration_value: u8,
    configuration: u8,
    attributes: u8,
    max_power: u8,
};

pub const InterfaceDescriptor = packed struct {
    length: u8 = @sizeOf(InterfaceDescriptor),
    descriptor_type: DescriptorType = .interface,
    interface_number: u8,
    alternate_setting: u8,
    num_endpoints: u8,
    interface_class: u8,
    interface_subclass: u8,
    interface_protocol: u8,
    interface: u8,
};

pub const EndpointDescriptor = packed struct {
    length: u8 = @sizeOf(EndpointDescriptor),
    descriptor_type: DescriptorType = .endpoint,
    endpoint_address: u8,
    attributes: u8,
    max_packet_size: u16,
    interval: u8,
};

// TODO: might not need this
pub const EndpointDescriptorLong = packed struct {
    length: u8,
    descriptor_type: DescriptorType,
    endpoint_address: u8,
    attributes: u8,
    max_packet_size: u16,
    interval: u8,
    refresh: u8,
    sync_addr: u8,
};
