const std = @import("std");
const objc = @import("objc").objc;
const ns = @import("objc").foundation.ns;
const c = @cImport({
    @cInclude("CoreMIDI/MidiServices.h");
});
const message = @import("message.zig");

pub const Event = message.Event;

pub const OnMidiEvent = fn (user_ctx: ?*anyopaque, ev: Event) void;

pub const Options = struct {
    user_ctx: ?*anyopaque,
    on_midi_event: *const OnMidiEvent,

    client_name: [*:0]const u8 = "mach.sysmidi client",
    port_name: [*:0]const u8 = "mach.sysmidi port",
};

pub const Client = struct {
    initialized: bool,
    handle: c.MIDIClientRef,
    dst: c.MIDIEndpointRef,
    port: c.MIDIPortRef,

    opened: bool,
    options: Options,
    src: c.MIDIEndpointRef,

    pub fn init() Client {
        return .{
            .initialized = false,
            .handle = undefined,
            .dst = undefined,
            .port = undefined,

            .opened = false,
            .options = undefined,
            .src = undefined,
        };
    }

    pub fn open(client: *Client, opt: Options) !void {
        if (!client.initialized) {
            const callback_ctx: ?*anyopaque = client;
            const name = c.CFStringCreateWithCString(null, opt.client_name, c.kCFStringEncodingUnicode);
            defer c.CFRelease(name);

            var status = c.MIDIClientCreate(name, notify_callback, callback_ctx, &client.handle);
            if (status != c.noErr) {
                return error.FailedToCreateClient;
            }

            const port_name = c.CFStringCreateWithCString(null, "Port", c.kCFStringEncodingUnicode);
            defer c.CFRelease(port_name);

            status = c.MIDIDestinationCreate(client.handle, port_name, read_callback, callback_ctx, &client.dst);
            if (status != c.noErr) {
                return error.FailedToCreateClientDestinationEndpoint;
            }
            status = c.MIDIInputPortCreate(client.handle, port_name, read_callback, callback_ctx, &client.port);
            if (status != c.noErr) {
                return error.FailedToCreateClientPort;
            }

            client.initialized = true;
        }

        if (client.opened) return;
        client.options = opt;
        client.src = c.MIDIGetSource(0); // TODO: index 0
        const conn_ref_con: ?*anyopaque = null;
        const status = c.MIDIPortConnectSource(client.port, client.src, conn_ref_con);
        if (status != c.noErr) {
            return error.FailedToOpenClientConnectSource;
        }
        client.opened = true;

        c.CFRunLoopRun();
    }

    pub fn deinit(client: *Client) void {
        client.close();
        client.initialized = false;
    }

    pub fn close(client: *Client) void {
        if (!client.opened) return;

        // Note: MIDIClientDispose should not be called, the Apple documentation explicitly states not
        // to do so: https://developer.apple.com/documentation/coremidi/1495335-midiclientdispose?language=objc

        _ = c.MIDIPortDisconnectSource(client.port, client.src);
        client.src = undefined;
        client.opened = false;
    }

    pub fn notify_callback(notification: [*c]const c.MIDINotification, callback_ctx: ?*anyopaque) callconv(.C) void {
        const client: *Client = @ptrCast(@alignCast(callback_ctx));
        _ = client;

        // *!
        // 	@enum		MIDINotificationMessageID
        // 	@abstract	Signifies the type of a MIDINotification.

        // 	@constant	kMIDIMsgSetupChanged	Some aspect of the current MIDISetup
        // 										has changed.  No data.  Should ignore this
        // 										message if messages 2-6 are handled.
        // 	@constant	kMIDIMsgObjectAdded		A device, entity or endpoint was added.
        // 										Structure is MIDIObjectAddRemoveNotification.
        // 										New in Mac OS X 10.2.
        // 	@constant	kMIDIMsgObjectRemoved	A device, entity or endpoint was removed.
        // 										Structure is MIDIObjectAddRemoveNotification.
        // 										New in Mac OS X 10.2.
        // 	@constant	kMIDIMsgPropertyChanged	An object's property was changed.
        // 										Structure is MIDIObjectPropertyChangeNotification.
        // 										New in Mac OS X 10.2.
        // 	@constant	kMIDIMsgThruConnectionsChanged	A persistent MIDI Thru connection was created
        // 										or destroyed.  No data.  New in Mac OS X 10.2.
        // 	@constant	kMIDIMsgSerialPortOwnerChanged	A persistent MIDI Thru connection was created
        // 										or destroyed.  No data.  New in Mac OS X 10.2.
        // 	@constant	kMIDIMsgIOError			A driver I/O error occurred.
        // */
        // typedef CF_ENUM(SInt32, MIDINotificationMessageID) {
        // 	kMIDIMsgSetupChanged			= 1,
        // 	kMIDIMsgObjectAdded				= 2,
        // 	kMIDIMsgObjectRemoved			= 3,
        // 	kMIDIMsgPropertyChanged			= 4,
        // 	kMIDIMsgThruConnectionsChanged	= 5,
        // 	kMIDIMsgSerialPortOwnerChanged	= 6,
        // 	kMIDIMsgIOError					= 7
        // };

        if (notification.*.messageID == c.kMIDIMsgObjectAdded) {
            // std.debug.print("kMIDIMsgObjectAdded", .{});
        }
    }

    // Returns ptr but aligned to 4-bytes on Apple silicon.
    // TODO: can use? std.mem.alignForward(comptime T: type, addr: T, alignment: T)
    fn alignedPtr(ptr: *const anyopaque) *const anyopaque {
        if (@import("builtin").target.cpu.arch == .aarch64) {
            // (Apple Silicon) 4-byte align
            return @ptrFromInt((@intFromPtr(ptr) + 3) & ~@as(usize, 3));
        } else {
            // (Intel) unaligned
            return ptr;
        }
    }

    // Note: CoreMIDI creates a high-priority receive thread on our behalf, and from that thread this
    // callback is called when incoming MIDI messages arive.
    pub fn read_callback(packet_list: [*c]const c.MIDIPacketList, callback_ctx: ?*anyopaque, src_conn_ref_con: ?*anyopaque) callconv(.C) void {
        read_callback_fallible(packet_list, callback_ctx, src_conn_ref_con) catch |err| @panic(@errorName(err));
    }

    pub fn read_callback_fallible(packet_list: [*c]const c.MIDIPacketList, callback_ctx: ?*anyopaque, src_conn_ref_con: ?*anyopaque) !void {
        _ = src_conn_ref_con;

        var client: *Client = @ptrCast(@alignCast(callback_ctx));

        // Note: MIDIPacketList and MIDIPacket are both variable-length structs (the struct does not
        // actually reflect the in-memory layout.) Additionally, when moving from one packet in the
        // list to the next, there are different alignment requirements. Specifically, MIDIPacket is
        // unaligned on Intel and 4-byte aligned on aarch64.

        // Define our own 'header' types that reflect the underlying data without using variable
        // length structs, and increment a pointer ourselves instead of using MIDIPacketNext as that
        // relies on undefined behavior.
        const MIDIPacketHeader = extern struct {
            timestamp: u64, // c.MIDITimeStamp,
            length: u16, // c.UInt16,
            first_byte: [1]u8,
        };
        const MIDIPacketListHeader = extern struct {
            num_packets: u32,
            first: [1]MIDIPacketHeader align(4),
        };

        // Load the packet list header / number of packets
        const list_header: *const MIDIPacketListHeader = @ptrCast(@alignCast(packet_list));
        const num_packets = list_header.num_packets;

        // Packet pointer that we will move forward depending on how large each packet is.
        var packet: *align(4) const MIDIPacketHeader = &list_header.first[0];
        var i: usize = 0;
        while (i < num_packets) : (i += 1) {
            if (packet.length == 0) continue;
            const data: []const u8 = @as([*]const u8, @ptrCast(&packet.first_byte[0]))[0..packet.length];
            // std.debug.print("\n", .{});
            // std.debug.print("num_packets: {}\n", .{num_packets});
            // std.debug.print("packet: {}\n", .{packet});
            // std.debug.print("data: {any}\n", .{data});

            var fbs = std.io.fixedBufferStream(data);
            var bits = std.io.bitReader(.Big, fbs.reader());

            const is_channel_message = try bits.readBitsNoEof(u1, 1) == 1;
            if (is_channel_message) {
                // Channel message (for specific channel)
                const message_type: message.StatusMessageType = @enumFromInt(try bits.readBitsNoEof(u3, 3));
                const channel: u4 = try bits.readBitsNoEof(u4, 4);
                switch (message_type) {
                    .note_on => client.options.on_midi_event(client.options.user_ctx, .{ .channel = .{ .note_on = .{
                        .channel = channel,
                        .key = try bits.readBitsNoEof(u8, 8),
                        .velocity = try bits.readBitsNoEof(u8, 8),
                    } } }),
                    .note_off => client.options.on_midi_event(client.options.user_ctx, .{ .channel = .{ .note_off = .{
                        .channel = channel,
                        .key = try bits.readBitsNoEof(u8, 8),
                        .velocity = try bits.readBitsNoEof(u8, 8),
                    } } }),
                    else => {},
                }

                // Note off                      8x      Key number          Note Off velocity
                // Note on                       9x      Key number          Note on velocity
                // Polyphonic Key Pressure       Ax      Key number          Amount of pressure
                // Control Change                Bx      Controller number   Controller value
                // Program Change                Cx      Program number      None
                // Channel Pressure              Dx      Pressure value      None
                // Pitch Bend                    Ex      MSB                 LSB

                // StatusMessageType
            } else {
                // System message (global)
            }

            const new_addr = @intFromPtr(packet) + @sizeOf(MIDIPacketHeader) + packet.length;
            packet = @ptrFromInt(std.mem.alignForward(usize, new_addr, 4));
        }
        // const alignment = 4;
        // var packet: *const MIDIPacketHeader align(4) = @ptrFromInt(
        //     std.mem.alignForward(
        //         usize,
        //         @intFromPtr(list_header) + @sizeOf(MIDIPacketListHeader),
        //         alignment,
        //     ),
        // );

        // // Read each packet
        // var i: usize = 0;
        // while (i < num_packets) : (i += 1) {
        //     // Load the packet header
        //     // TODO: correct align() for Intel
        //     std.debug.print("ptr: {}\n", .{@intFromPtr(ptr)});
        //     const header: *const MIDIPacketHeader = @ptrCast(@alignCast(ptr));
        //     ptr = @ptrFromInt(@intFromPtr(ptr) + @sizeOf(MIDIPacketHeader));

        //     // Load the packet data
        //     const data: []const u8 = @as([*]const u8, @ptrCast(ptr))[0..header.length];
        //     ptr = @ptrFromInt(@intFromPtr(ptr) + header.length);

        //     std.debug.print("timestamp: {any}, length: {}, len: {}, data: {any}\n", .{ header.*.timestamp, header.*.length, data.len, data });
        //     break;

        //     // std.debug.print("packet: {any}\n", .{packet_list.*.packet[0]});

        //     // var fbs = std.io.fixedBufferStream(data);
        //     // var bits = std.io.bitReader(.Big, fbs.reader());
        //     // _ = bits;

        //     // const is_data_message = bits.readBitsNoEof(u1, 1);
        //     // std.debug.print("packet: {any}\n", .{is_data_message});

        //     // if (data.len > 0) {
        //     //     const status: message.StatusByte = @bitCast(data[0]);
        //     //     if (status.is_data_message) {
        //     //         const data_message: message.StatusByteDataMessage = @bitCast(status.remaining);
        //     //         switch (data_message.status_message_type) {
        //     //             .note_on => {
        //     //                 std.debug.print("note on\n", .{});
        //     //             },
        //     //             .note_off => {
        //     //                 std.debug.print("note off\n", .{});
        //     //             },
        //     //             else => {},
        //     //         }
        //     //     }
        //     // }

        //     // unaligned_ptr = MIDIPacketNext(packet);
        // }

        // var packets: [*c]c.MIDIPacket = @constCast(&packet_list.*.packet[0]);
        // for (packets[0..num_packets]) |packet| {
        //     if (packet.length <= packet.data.len) {

        //     }

        //     std.debug.print("\n", .{});
        // }

        // var packet: [*c]c.MIDIPacket = @constCast(&packet_list.*.packet); // discard const
        // var j: usize = 0;
        // while (j < packet_list.*.numPackets) : (j += 1) {
        //     var i: usize = 0;
        //     while (i < packet.*.length and i < packet.*.data.len) : (i += 1) {
        //         std.debug.print("{X} ", .{packet.*.data[i]});
        //     }
        //     std.debug.print("\n", .{});
        //     std.debug.print("HERE? {} {}\n", .{ j, packet_list.*.numPackets - 1 });
        //     if (j != packet_list.*.numPackets - 1) packet = c.MIDIPacketNext(packet);
        // }

        //     if (gOutPort != NULL && gDest != NULL) {
        //         MIDIPacket *packet = (MIDIPacket *)pktlist->packet; // remove const (!)
        //         for (unsigned int j = 0; j < pktlist->numPackets; ++j) {
        //             for (int i = 0; i < packet->length; ++i) {
        // //              printf("%02X ", packet->data[i]);

        //                 // rechannelize status bytes
        //                 if (packet->data[i] >= 0x80 && packet->data[i] < 0xF0)
        //                     packet->data[i] = (packet->data[i] & 0xF0) | gChannel;
        //             }

        // //          printf("\n");
        //             packet = MIDIPacketNext(packet);
        //         }

        //         MIDISend(gOutPort, gDest, pktlist);

    }
};

// pub fn MIDIPacketNext(arg_pkt: *const MIDIPacket) *anyopaque {
//     var pkt = arg_pkt;
//     const p = (@as(usize, @intCast(@intFromPtr(&pkt.*.data[pkt.*.length]))) +% @as(usize, @bitCast(@as(c_long, @as(c_int, 3))))) & @as(usize, @bitCast(@as(c_long, ~@as(c_int, 3))));
//     return @ptrFromInt(p);
// }

// pub const MIDIPacket = extern struct {
//     timeStamp: c.MIDITimeStamp,
//     length: u16,
//     data: [256]u8,
// };
