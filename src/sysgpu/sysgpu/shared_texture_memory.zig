const Texture = @import("texture.zig").Texture;
const Bool32 = @import("main.zig").Bool32;
const Extent3D = @import("main.zig").Extent3D;
const SharedFence = @import("shared_fence.zig").SharedFence;
const ChainedStruct = @import("main.zig").ChainedStruct;
const ChainedStructOut = @import("main.zig").ChainedStructOut;

pub const SharedTextureMemory = opaque {
    pub const Properties = extern struct {
        next_in_chain: *const ChainedStruct,
        usage: Texture.UsageFlags,
        size: Extent3D,
        format: Texture.Format,
    };

    pub const VkImageDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_vk_image_descriptor },
        vk_format: i32,
        vk_usage_flags: Texture.UsageFlags,
        vk_extent3D: Extent3D,
    };

    pub const AHardwareBufferDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_a_hardware_buffer_descriptor },
        handle: *anyopaque,
    };

    pub const BeginAccessDescriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            vk_image_layout_begin_state: *const VkImageLayoutBeginState,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        initialized: Bool32,
        fence_count: usize,
        fences: *const SharedFence,
        signaled_values: *const u64,
    };

    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            a_hardware_buffer_descriptor: *const AHardwareBufferDescriptor,
            dma_buf_descriptor: *const DmaBufDescriptor,
            dxgi_shared_handle_descriptor: *const DXGISharedHandleDescriptor,
            egl_image_descriptor: *const EGLImageDescriptor,
            io_surface_descriptor: *const IOSurfaceDescriptor,
            opaque_fd_descriptor: *const OpaqueFDDescriptor,
            vk_dedicated_allocation_descriptor: *const VkDedicatedAllocationDescriptor,
            zircon_handle_descriptor: *const ZirconHandleDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*]const u8,
    };

    pub const DmaBufDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_dma_buf_descriptor },
        memory_fd: c_int,
        allocation_size: u64,
        drm_modifier: u64,
        plane_count: usize,
        plane_offsets: *const u64,
        plane_strides: *const u32,
    };

    pub const DXGISharedHandleDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_dxgi_shared_handle_descriptor },
        handle: *anyopaque,
    };

    pub const EGLImageDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_egl_image_descriptor },
        image: *anyopaque,
    };

    pub const EndAccessState = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            vk_image_layout_end_state: *const VkImageLayoutEndState,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        initialized: Bool32,
        fence_count: usize,
        fences: *const SharedFence,
        signaled_values: *const u64,
    };

    pub const IOSurfaceDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_io_surface_descriptor },
        ioSurface: *anyopaque,
    };

    pub const OpaqueFDDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_opaque_fd_descriptor },
        memory_fd: c_int,
        allocation_size: u64,
    };

    pub const VkDedicatedAllocationDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_vk_dedicated_allocation_descriptor },
        dedicated_allocation: Bool32,
    };

    pub const VkImageLayoutBeginState = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_vk_image_layout_begin_state },
        old_layout: i32,
        new_layout: i32,
    };

    pub const VkImageLayoutEndState = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_vk_image_layout_end_state },
        old_layout: i32,
        new_layout: i32,
    };

    pub const ZirconHandleDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shared_texture_memory_zircon_handle_descriptor },
        memory_fd: u32,
        allocation_size: u64,
    };
};
