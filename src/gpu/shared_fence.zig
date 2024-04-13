const ChainedStruct = @import("main.zig").ChainedStruct;
const ChainedStructOut = @import("main.zig").ChainedStructOut;

pub const SharedFence = opaque {
    pub const Type = enum(u32) {
        shared_fence_type_undefined = 0x00000000,
        shared_fence_type_vk_semaphore_opaque_fd = 0x00000001,
        shared_fence_type_vk_semaphore_sync_fd = 0x00000002,
        shared_fence_type_vk_semaphore_zircon_handle = 0x00000003,
        shared_fence_type_dxgi_shared_handle = 0x00000004,
        shared_fence_type_mtl_shared_event = 0x00000005,
    };

    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            vk_semaphore_opaque_fd_descriptor: *const VkSemaphoreOpaqueFDDescriptor,
            vk_semaphore_sync_fd_descriptor: *const VkSemaphoreSyncFDDescriptor,
            vk_semaphore_zircon_handle_descriptor: *const VkSemaphoreZirconHandleDescriptor,
            dxgi_shared_handle_descriptor: *const DXGISharedHandleDescriptor,
            mtl_shared_event_descriptor: *const MTLSharedEventDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*]const u8,
    };

    pub const DXGISharedHandleDescriptor = extern struct {
        chain: ChainedStruct,
        handle: *anyopaque,
    };

    pub const DXGISharedHandleExportInfo = extern struct {
        chain: ChainedStructOut,
        handle: *anyopaque,
    };

    pub const ExportInfo = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStructOut,
            dxgi_shared_handle_export_info: *const DXGISharedHandleExportInfo,
            mtl_shared_event_export_info: *const MTLSharedEventExportInfo,
            vk_semaphore_opaque_fd_export_info: *const VkSemaphoreOpaqueFDExportInfo,
            vk_semaphore_sync_fd_export_info: *const VkSemaphoreSyncFDExportInfo,
            vk_semaphore_zircon_handle_export_info: *const VkSemaphoreZirconHandleExportInfo,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        type: Type,
    };

    pub const MTLSharedEventDescriptor = extern struct {
        chain: ChainedStruct,
        shared_event: *anyopaque,
    };

    pub const MTLSharedEventExportInfo = extern struct {
        chain: ChainedStructOut,
        shared_event: *anyopaque,
    };

    pub const VkSemaphoreOpaqueFDDescriptor = extern struct {
        chain: ChainedStruct,
        handle: c_int,
    };

    pub const VkSemaphoreOpaqueFDExportInfo = extern struct {
        chain: ChainedStructOut,
        handle: c_int,
    };

    pub const VkSemaphoreSyncFDDescriptor = extern struct {
        chain: ChainedStruct,
        handle: c_int,
    };

    pub const VkSemaphoreSyncFDExportInfo = extern struct {
        chain: ChainedStructOut,
        handle: c_int,
    };

    pub const VkSemaphoreZirconHandleDescriptor = extern struct {
        chain: ChainedStruct,
        handle: u32,
    };

    pub const VkSemaphoreZirconHandleExportInfo = extern struct {
        chain: ChainedStructOut,
        handle: u32,
    };
};
