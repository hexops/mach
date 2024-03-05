const std = @import("std");
const builtin = @import("builtin");
const sysgpu = @import("sysgpu/main.zig");
const limits = @import("limits.zig");
const shader = @import("shader.zig");
const utils = @import("utils.zig");
const c = @import("d3d12/c.zig");
const conv = @import("d3d12/conv.zig");
const gpu_allocator = @import("gpu_allocator.zig");

const log = std.log.scoped(.d3d12);

// TODO - need to tweak all these sizes and make a better allocator
const general_heap_size = 1024;
const general_block_size = 16;
const sampler_heap_size = 1024;
const sampler_block_size = 16;
const rtv_heap_size = 1024;
const rtv_block_size = 16;
const dsv_heap_size = 1024;
const dsv_block_size = 1;
const upload_page_size = 64 * 1024 * 1024; // TODO - split writes and/or support large uploads
const max_back_buffer_count = 3;

var allocator: std.mem.Allocator = undefined;
var debug_enabled: bool = undefined;
var gpu_validation_enabled: bool = undefined;

// workaround c-translation errors
const DXGI_PRESENT_ALLOW_TEARING: c.UINT = 0x00000200;

pub const InitOptions = struct {
    debug_enabled: bool = builtin.mode == .Debug,
    gpu_validation_enabled: bool = builtin.mode == .Debug,
};

pub fn init(alloc: std.mem.Allocator, options: InitOptions) !void {
    allocator = alloc;
    debug_enabled = options.debug_enabled;
    gpu_validation_enabled = options.gpu_validation_enabled;
}

const MapCallback = struct {
    buffer: *Buffer,
    callback: sysgpu.Buffer.MapCallback,
    userdata: ?*anyopaque,
};

fn setDebugName(object: *c.ID3D12Object, opt_label: ?[*:0]const u8) void {
    if (opt_label) |label| {
        const slice = std.mem.span(label);

        _ = object.lpVtbl.*.SetPrivateData.?(
            object,
            &c.WKPDID_D3DDebugObjectName,
            @intCast(slice.len),
            slice.ptr,
        );
    } else {
        _ = object.lpVtbl.*.SetPrivateData.?(
            object,
            &c.WKPDID_D3DDebugObjectName,
            0,
            null,
        );
    }
}

pub const Instance = struct {
    manager: utils.Manager(Instance) = .{},
    dxgi_factory: *c.IDXGIFactory4,
    allow_tearing: bool,

    pub fn init(desc: *const sysgpu.Instance.Descriptor) !*Instance {
        // TODO
        _ = desc;

        var hr: c.HRESULT = undefined;

        // DXGI Factory
        var dxgi_factory: *c.IDXGIFactory4 = undefined;
        hr = c.CreateDXGIFactory2(
            if (debug_enabled) c.DXGI_CREATE_FACTORY_DEBUG else 0,
            &c.IID_IDXGIFactory4,
            @ptrCast(&dxgi_factory),
        );
        if (hr != c.S_OK) {
            return error.CreateDXGIFactoryFailed;
        }
        errdefer _ = dxgi_factory.lpVtbl.*.Release.?(dxgi_factory);

        var opt_dxgi_factory5: ?*c.IDXGIFactory5 = null;
        _ = dxgi_factory.lpVtbl.*.QueryInterface.?(
            dxgi_factory,
            &c.IID_IDXGIFactory5,
            @ptrCast(&opt_dxgi_factory5),
        );
        defer _ = if (opt_dxgi_factory5) |dxgi_factory5| dxgi_factory5.lpVtbl.*.Release.?(dxgi_factory5);

        // Feature support
        var allow_tearing: c.BOOL = c.FALSE;
        if (opt_dxgi_factory5) |dxgi_factory5| {
            hr = dxgi_factory5.lpVtbl.*.CheckFeatureSupport.?(
                dxgi_factory5,
                c.DXGI_FEATURE_PRESENT_ALLOW_TEARING,
                &allow_tearing,
                @sizeOf(@TypeOf(allow_tearing)),
            );
        }

        // D3D12 Debug Layer
        if (debug_enabled) {
            var debug_controller: *c.ID3D12Debug1 = undefined;
            hr = c.D3D12GetDebugInterface(&c.IID_ID3D12Debug1, @ptrCast(&debug_controller));
            if (hr == c.S_OK) {
                defer _ = debug_controller.lpVtbl.*.Release.?(debug_controller);
                debug_controller.lpVtbl.*.EnableDebugLayer.?(debug_controller);
                if (gpu_validation_enabled) {
                    debug_controller.lpVtbl.*.SetEnableGPUBasedValidation.?(
                        debug_controller,
                        c.TRUE,
                    );
                }
            }
        }

        // Result
        const instance = try allocator.create(Instance);
        instance.* = .{
            .dxgi_factory = dxgi_factory,
            .allow_tearing = allow_tearing == c.TRUE,
        };
        return instance;
    }

    pub fn deinit(instance: *Instance) void {
        const dxgi_factory = instance.dxgi_factory;

        _ = dxgi_factory.lpVtbl.*.Release.?(dxgi_factory);
        Instance.reportLiveObjects();
        allocator.destroy(instance);
    }

    pub fn createSurface(instance: *Instance, desc: *const sysgpu.Surface.Descriptor) !*Surface {
        return Surface.init(instance, desc);
    }

    // Internal
    pub fn reportLiveObjects() void {
        var hr: c.HRESULT = undefined;

        var dxgi_debug: *c.IDXGIDebug = undefined;
        hr = c.DXGIGetDebugInterface1(0, &c.IID_IDXGIDebug, @ptrCast(&dxgi_debug));
        if (hr == c.S_OK) {
            defer _ = dxgi_debug.lpVtbl.*.Release.?(dxgi_debug);

            _ = dxgi_debug.lpVtbl.*.ReportLiveObjects.?(
                dxgi_debug,
                c.DXGI_DEBUG_ALL,
                c.DXGI_DEBUG_RLO_ALL,
            );
        }
    }
};

pub const Adapter = struct {
    manager: utils.Manager(Adapter) = .{},
    instance: *Instance,
    dxgi_adapter: *c.IDXGIAdapter1,
    d3d_device: *c.ID3D12Device,
    dxgi_desc: c.DXGI_ADAPTER_DESC1,

    pub fn init(instance: *Instance, options: *const sysgpu.RequestAdapterOptions) !*Adapter {
        // TODO - choose appropriate device from options
        _ = options;

        const dxgi_factory = instance.dxgi_factory;
        var hr: c.HRESULT = undefined;

        var i: u32 = 0;
        var dxgi_adapter: *c.IDXGIAdapter1 = undefined;
        while (dxgi_factory.lpVtbl.*.EnumAdapters1.?(
            dxgi_factory,
            i,
            @ptrCast(&dxgi_adapter),
        ) != c.DXGI_ERROR_NOT_FOUND) : (i += 1) {
            defer _ = dxgi_adapter.lpVtbl.*.Release.?(dxgi_adapter);

            var dxgi_desc: c.DXGI_ADAPTER_DESC1 = undefined;
            hr = dxgi_adapter.lpVtbl.*.GetDesc1.?(
                dxgi_adapter,
                &dxgi_desc,
            );
            std.debug.assert(hr == c.S_OK);

            if ((dxgi_desc.Flags & c.DXGI_ADAPTER_FLAG_SOFTWARE) != 0)
                continue;

            var d3d_device: *c.ID3D12Device = undefined;
            hr = c.D3D12CreateDevice(
                @ptrCast(dxgi_adapter),
                c.D3D_FEATURE_LEVEL_11_0,
                &c.IID_ID3D12Device,
                @ptrCast(&d3d_device),
            );
            if (hr == c.S_OK) {
                _ = dxgi_adapter.lpVtbl.*.AddRef.?(dxgi_adapter);

                const adapter = try allocator.create(Adapter);
                adapter.* = .{
                    .instance = instance,
                    .dxgi_adapter = dxgi_adapter,
                    .d3d_device = d3d_device,
                    .dxgi_desc = dxgi_desc,
                };
                return adapter;
            }
        }

        return error.NoAdapterFound;
    }

    pub fn deinit(adapter: *Adapter) void {
        const dxgi_adapter = adapter.dxgi_adapter;
        const d3d_device = adapter.d3d_device;
        _ = dxgi_adapter.lpVtbl.*.Release.?(dxgi_adapter);
        _ = d3d_device.lpVtbl.*.Release.?(d3d_device);
        allocator.destroy(adapter);
    }

    pub fn createDevice(adapter: *Adapter, desc: ?*const sysgpu.Device.Descriptor) !*Device {
        return Device.init(adapter, desc);
    }

    pub fn getProperties(adapter: *Adapter) sysgpu.Adapter.Properties {
        const dxgi_desc = adapter.dxgi_desc;

        return .{
            .vendor_id = dxgi_desc.VendorId,
            .vendor_name = "", // TODO
            .architecture = "", // TODO
            .device_id = dxgi_desc.DeviceId,
            .name = "", // TODO - wide to ascii - dxgi_desc.Description
            .driver_description = "", // TODO
            .adapter_type = .unknown,
            .backend_type = .d3d12,
            .compatibility_mode = .false,
        };
    }
};

pub const Surface = struct {
    manager: utils.Manager(Surface) = .{},
    hwnd: c.HWND,

    pub fn init(instance: *Instance, desc: *const sysgpu.Surface.Descriptor) !*Surface {
        _ = instance;

        if (utils.findChained(sysgpu.Surface.DescriptorFromWindowsHWND, desc.next_in_chain.generic)) |win_desc| {
            // workaround issues with @alignCast panicking as HWND is not a real pointer
            var hwnd: c.HWND = undefined;
            @memcpy(std.mem.asBytes(&hwnd), std.mem.asBytes(&win_desc.hwnd));

            const surface = try allocator.create(Surface);
            surface.* = .{ .hwnd = hwnd };
            return surface;
        } else {
            return error.InvalidDescriptor;
        }
    }

    pub fn deinit(surface: *Surface) void {
        allocator.destroy(surface);
    }
};

pub const Device = struct {
    manager: utils.Manager(Device) = .{},
    adapter: *Adapter,
    d3d_device: *c.ID3D12Device,
    queue: *Queue,
    general_heap: DescriptorHeap = undefined,
    sampler_heap: DescriptorHeap = undefined,
    rtv_heap: DescriptorHeap = undefined,
    dsv_heap: DescriptorHeap = undefined,
    command_manager: CommandManager = undefined,
    streaming_manager: StreamingManager = undefined,
    reference_trackers: std.ArrayListUnmanaged(*ReferenceTracker) = .{},
    mem_allocator: MemoryAllocator = undefined,
    map_callbacks: std.ArrayListUnmanaged(MapCallback) = .{},

    lost_cb: ?sysgpu.Device.LostCallback = null,
    lost_cb_userdata: ?*anyopaque = null,
    log_cb: ?sysgpu.LoggingCallback = null,
    log_cb_userdata: ?*anyopaque = null,
    err_cb: ?sysgpu.ErrorCallback = null,
    err_cb_userdata: ?*anyopaque = null,

    pub fn init(adapter: *Adapter, desc: ?*const sysgpu.Device.Descriptor) !*Device {
        const d3d_device = adapter.d3d_device;
        var hr: c.HRESULT = undefined;

        // TODO
        _ = desc;

        // Debug Configuration
        if (debug_enabled) {
            var info_queue: *c.ID3D12InfoQueue = undefined;

            hr = d3d_device.lpVtbl.*.QueryInterface.?(
                d3d_device,
                &c.IID_ID3D12InfoQueue,
                @ptrCast(&info_queue),
            );
            if (hr == c.S_OK) {
                defer _ = info_queue.lpVtbl.*.Release.?(info_queue);

                var deny_ids = [_]c.D3D12_MESSAGE_ID{
                    c.D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
                    c.D3D12_MESSAGE_ID_CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE,
                    1328, //c.D3D12_MESSAGE_ID_CREATERESOURCE_STATE_IGNORED, // Required for naive barrier strategy, can be removed with render graphs
                };
                var severities = [_]c.D3D12_MESSAGE_SEVERITY{
                    c.D3D12_MESSAGE_SEVERITY_INFO,
                    c.D3D12_MESSAGE_SEVERITY_MESSAGE,
                };
                var filter = c.D3D12_INFO_QUEUE_FILTER{
                    .AllowList = .{
                        .NumCategories = 0,
                        .pCategoryList = null,
                        .NumSeverities = 0,
                        .pSeverityList = null,
                        .NumIDs = 0,
                        .pIDList = null,
                    },
                    .DenyList = .{
                        .NumCategories = 0,
                        .pCategoryList = null,
                        .NumSeverities = severities.len,
                        .pSeverityList = &severities,
                        .NumIDs = deny_ids.len,
                        .pIDList = &deny_ids,
                    },
                };

                hr = info_queue.lpVtbl.*.PushStorageFilter.?(
                    info_queue,
                    &filter,
                );
                std.debug.assert(hr == c.S_OK);
            }
        }

        const queue = try allocator.create(Queue);
        errdefer allocator.destroy(queue);

        // Object
        var device = try allocator.create(Device);
        device.* = .{
            .adapter = adapter,
            .d3d_device = d3d_device,
            .queue = queue,
        };

        // Initialize
        device.queue.* = try Queue.init(device);
        errdefer queue.deinit();

        device.general_heap = try DescriptorHeap.init(
            device,
            c.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV,
            c.D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE,
            general_heap_size,
            general_block_size,
        );
        errdefer device.general_heap.deinit();

        device.sampler_heap = try DescriptorHeap.init(
            device,
            c.D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER,
            c.D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE,
            sampler_heap_size,
            sampler_block_size,
        );
        errdefer device.sampler_heap.deinit();

        device.rtv_heap = try DescriptorHeap.init(
            device,
            c.D3D12_DESCRIPTOR_HEAP_TYPE_RTV,
            c.D3D12_DESCRIPTOR_HEAP_FLAG_NONE,
            rtv_heap_size,
            rtv_block_size,
        );
        errdefer device.rtv_heap.deinit();

        device.dsv_heap = try DescriptorHeap.init(
            device,
            c.D3D12_DESCRIPTOR_HEAP_TYPE_DSV,
            c.D3D12_DESCRIPTOR_HEAP_FLAG_NONE,
            dsv_heap_size,
            dsv_block_size,
        );
        errdefer device.dsv_heap.deinit();

        device.command_manager = CommandManager.init(device);

        device.streaming_manager = try StreamingManager.init(device);
        errdefer device.streaming_manager.deinit();

        try device.mem_allocator.init(device);

        return device;
    }

    pub fn deinit(device: *Device) void {
        if (device.lost_cb) |lost_cb| {
            lost_cb(.destroyed, "Device was destroyed.", device.lost_cb_userdata);
        }

        device.queue.waitUntil(device.queue.fence_value);
        device.processQueuedOperations();

        device.map_callbacks.deinit(allocator);
        device.reference_trackers.deinit(allocator);
        device.streaming_manager.deinit();
        device.command_manager.deinit();
        device.dsv_heap.deinit();
        device.rtv_heap.deinit();
        device.sampler_heap.deinit();
        device.general_heap.deinit();
        device.queue.manager.release();

        device.mem_allocator.deinit();

        allocator.destroy(device.queue);
        allocator.destroy(device);
    }

    pub fn createBindGroup(device: *Device, desc: *const sysgpu.BindGroup.Descriptor) !*BindGroup {
        return BindGroup.init(device, desc);
    }

    pub fn createBindGroupLayout(device: *Device, desc: *const sysgpu.BindGroupLayout.Descriptor) !*BindGroupLayout {
        return BindGroupLayout.init(device, desc);
    }

    pub fn createBuffer(device: *Device, desc: *const sysgpu.Buffer.Descriptor) !*Buffer {
        return Buffer.init(device, desc);
    }

    pub fn createCommandEncoder(device: *Device, desc: *const sysgpu.CommandEncoder.Descriptor) !*CommandEncoder {
        return CommandEncoder.init(device, desc);
    }

    pub fn createComputePipeline(device: *Device, desc: *const sysgpu.ComputePipeline.Descriptor) !*ComputePipeline {
        return ComputePipeline.init(device, desc);
    }

    pub fn createPipelineLayout(device: *Device, desc: *const sysgpu.PipelineLayout.Descriptor) !*PipelineLayout {
        return PipelineLayout.init(device, desc);
    }

    pub fn createRenderPipeline(device: *Device, desc: *const sysgpu.RenderPipeline.Descriptor) !*RenderPipeline {
        return RenderPipeline.init(device, desc);
    }

    pub fn createSampler(device: *Device, desc: *const sysgpu.Sampler.Descriptor) !*Sampler {
        return Sampler.init(device, desc);
    }

    pub fn createShaderModuleAir(device: *Device, air: *shader.Air, label: [*:0]const u8) !*ShaderModule {
        _ = label;
        return ShaderModule.initAir(device, air);
    }

    pub fn createShaderModuleSpirv(device: *Device, code: [*]const u32, code_size: u32) !*ShaderModule {
        _ = code;
        _ = code_size;
        _ = device;
        return error.Unsupported;
    }

    pub fn createShaderModuleHLSL(device: *Device, code: []const u8) !*ShaderModule {
        _ = device;
        const module = try allocator.create(ShaderModule);
        module.* = .{ .code = .{ .code = code } };
        return module;
    }

    pub fn createShaderModuleMSL(
        device: *Device,
        label: [*:0]const u8,
        code: []const u8,
        workgroup_size: sysgpu.ShaderModule.WorkgroupSize,
    ) !*ShaderModule {
        _ = label;
        _ = code;
        _ = device;
        _ = workgroup_size;
        return error.Unsupported;
    }

    pub fn createSwapChain(device: *Device, surface: *Surface, desc: *const sysgpu.SwapChain.Descriptor) !*SwapChain {
        return SwapChain.init(device, surface, desc);
    }

    pub fn createTexture(device: *Device, desc: *const sysgpu.Texture.Descriptor) !*Texture {
        return Texture.init(device, desc);
    }

    pub fn getQueue(device: *Device) !*Queue {
        return device.queue;
    }

    pub fn tick(device: *Device) !void {
        device.processQueuedOperations();
    }

    // Internal
    pub fn processQueuedOperations(device: *Device) void {
        // Reference trackers
        {
            const fence = device.queue.fence;
            const completed_value = fence.lpVtbl.*.GetCompletedValue.?(fence);

            var i: usize = 0;
            while (i < device.reference_trackers.items.len) {
                const reference_tracker = device.reference_trackers.items[i];

                if (reference_tracker.fence_value <= completed_value) {
                    reference_tracker.deinit();
                    _ = device.reference_trackers.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }

        // MapAsync
        {
            var i: usize = 0;
            while (i < device.map_callbacks.items.len) {
                const map_callback = device.map_callbacks.items[i];

                if (map_callback.buffer.gpu_count == 0) {
                    map_callback.buffer.executeMapAsync(map_callback);

                    _ = device.map_callbacks.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }
    }

    pub fn createD3dBuffer(device: *Device, usage: sysgpu.Buffer.UsageFlags, size: u64) !Resource {
        const resource_size = conv.d3d12ResourceSizeForBuffer(size, usage);

        const heap_type = conv.d3d12HeapType(usage);
        const resource_desc = c.D3D12_RESOURCE_DESC{
            .Dimension = c.D3D12_RESOURCE_DIMENSION_BUFFER,
            .Alignment = 0,
            .Width = resource_size,
            .Height = 1,
            .DepthOrArraySize = 1,
            .MipLevels = 1,
            .Format = c.DXGI_FORMAT_UNKNOWN,
            .SampleDesc = .{ .Count = 1, .Quality = 0 },
            .Layout = c.D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
            .Flags = conv.d3d12ResourceFlagsForBuffer(usage),
        };
        const read_state = conv.d3d12ResourceStatesForBufferRead(usage);
        const initial_state = conv.d3d12ResourceStatesInitial(heap_type, read_state);

        const create_desc = ResourceCreateDescriptor{
            .location = if (usage.map_write)
                .gpu_to_cpu
            else if (usage.map_read)
                .cpu_to_gpu
            else
                .gpu_only,
            .resource_desc = &resource_desc,
            .clear_value = null,
            .resource_category = .buffer,
            .initial_state = initial_state,
        };

        return try device.mem_allocator.createResource(&create_desc);
    }
};

pub const ResourceCategory = enum {
    buffer,
    rtv_dsv_texture,
    other_texture,

    pub inline fn heapUsable(self: ResourceCategory, heap: HeapCategory) bool {
        return switch (heap) {
            .all => true,
            .buffer => self == .buffer,
            .rtv_dsv_texture => self == .rtv_dsv_texture,
            .other_texture => self == .other_texture,
        };
    }
};

pub const HeapCategory = enum {
    all,
    buffer,
    rtv_dsv_texture,
    other_texture,
};

pub const AllocationCreateDescriptor = struct {
    location: MemoryLocation,
    size: u64,
    alignment: u64,
    resource_category: ResourceCategory,
};

pub const ResourceCreateDescriptor = struct {
    location: MemoryLocation,
    resource_category: ResourceCategory,
    resource_desc: *const c.D3D12_RESOURCE_DESC,
    clear_value: ?*const c.D3D12_CLEAR_VALUE,
    initial_state: c.D3D12_RESOURCE_STATES,
};

pub const MemoryLocation = enum {
    unknown,
    gpu_only,
    cpu_to_gpu,
    gpu_to_cpu,
};

pub const AllocationSizes = struct {
    device_memblock_size: u64 = 256 * 1024 * 1024,
    host_memblock_size: u64 = 64 * 1024 * 1024,

    const four_mb = 4 * 1024 * 1024;
    const two_hundred_fifty_six_mb = 256 * 1024 * 1024;

    pub fn init(
        device_memblock_size: u64,
        host_memblock_size: u64,
    ) AllocationSizes {
        var use_device_memblock_size = std.math.clamp(
            device_memblock_size,
            four_mb,
            two_hundred_fifty_six_mb,
        );
        var use_host_memblock_size = std.math.clamp(
            host_memblock_size,
            four_mb,
            two_hundred_fifty_six_mb,
        );

        if (use_device_memblock_size % four_mb != 0) {
            use_device_memblock_size = four_mb * (@divFloor(use_device_memblock_size, four_mb) + 1);
        }
        if (use_host_memblock_size % four_mb != 0) {
            use_host_memblock_size = four_mb * (@divFloor(use_host_memblock_size, four_mb) + 1);
        }

        return .{
            .device_memblock_size = use_device_memblock_size,
            .host_memblock_size = use_host_memblock_size,
        };
    }
};

/// Stores a group of heaps
pub const MemoryAllocator = struct {
    const max_memory_groups = 9;
    device: *Device,

    memory_groups: std.BoundedArray(MemoryGroup, max_memory_groups),
    allocation_sizes: AllocationSizes,

    /// a single heap,
    /// use the gpu_allocator field to allocate chunks of memory
    pub const MemoryHeap = struct {
        index: usize,
        heap: *c.ID3D12Heap,
        size: u64,
        gpu_allocator: gpu_allocator.Allocator,

        pub fn init(
            group: *MemoryGroup,
            index: usize,
            size: u64,
            dedicated: bool,
        ) gpu_allocator.Error!MemoryHeap {
            const heap = blk: {
                var desc = c.D3D12_HEAP_DESC{
                    .SizeInBytes = size,
                    .Properties = group.heap_properties,
                    .Alignment = @intCast(c.D3D12_DEFAULT_MSAA_RESOURCE_PLACEMENT_ALIGNMENT),
                    .Flags = switch (group.heap_category) {
                        .all => c.D3D12_HEAP_FLAG_NONE,
                        .buffer => c.D3D12_HEAP_FLAG_ALLOW_ONLY_BUFFERS,
                        .rtv_dsv_texture => c.D3D12_HEAP_FLAG_ALLOW_ONLY_RT_DS_TEXTURES,
                        .other_texture => c.D3D12_HEAP_FLAG_ALLOW_ONLY_NON_RT_DS_TEXTURES,
                    },
                };

                var heap: ?*c.ID3D12Heap = null;
                const d3d_device = group.owning_pool.device.d3d_device;
                const hr = d3d_device.lpVtbl.*.CreateHeap.?(
                    d3d_device,
                    &desc,
                    &c.IID_ID3D12Heap,
                    @ptrCast(&heap),
                );
                if (hr == c.E_OUTOFMEMORY) return gpu_allocator.Error.OutOfMemory;
                if (hr != c.S_OK) return gpu_allocator.Error.Other;

                break :blk heap.?;
            };

            return MemoryHeap{
                .index = index,
                .heap = heap,
                .size = size,
                .gpu_allocator = if (dedicated)
                    try gpu_allocator.Allocator.initDedicatedBlockAllocator(size)
                else
                    try gpu_allocator.Allocator.initOffsetAllocator(allocator, @intCast(size), null),
            };
        }

        pub fn deinit(self: *MemoryHeap) void {
            _ = self.heap.lpVtbl.*.Release.?(self.heap);
            self.gpu_allocator.deinit();
        }
    };

    /// a group of multiple heaps with a single heap type
    pub const MemoryGroup = struct {
        owning_pool: *MemoryAllocator,

        memory_location: MemoryLocation,
        heap_category: HeapCategory,
        heap_properties: c.D3D12_HEAP_PROPERTIES,

        heaps: std.ArrayListUnmanaged(?MemoryHeap),

        pub const GroupAllocation = struct {
            allocation: gpu_allocator.Allocation,
            heap: *MemoryHeap,
            size: u64,
        };

        pub fn init(
            owner: *MemoryAllocator,
            memory_location: MemoryLocation,
            category: HeapCategory,
            properties: c.D3D12_HEAP_PROPERTIES,
        ) MemoryGroup {
            return .{
                .owning_pool = owner,
                .memory_location = memory_location,
                .heap_category = category,
                .heap_properties = properties,
                .heaps = .{},
            };
        }

        pub fn deinit(self: *MemoryGroup) void {
            for (self.heaps.items) |*heap| {
                if (heap.*) |*h| h.deinit();
            }
            self.heaps.deinit(allocator);
        }

        pub fn allocate(self: *MemoryGroup, size: u64) gpu_allocator.Error!GroupAllocation {
            const memblock_size: u64 = if (self.heap_properties.Type == c.D3D12_HEAP_TYPE_DEFAULT)
                self.owning_pool.allocation_sizes.device_memblock_size
            else
                self.owning_pool.allocation_sizes.host_memblock_size;
            if (size > memblock_size) {
                return self.allocateDedicated(size);
            }

            var empty_heap_index: ?usize = null;
            for (self.heaps.items, 0..) |*heap, index| {
                if (heap.*) |*h| {
                    const allocation = h.gpu_allocator.allocate(@intCast(size)) catch |err| switch (err) {
                        gpu_allocator.Error.OutOfMemory => continue,
                        else => return err,
                    };
                    return GroupAllocation{
                        .allocation = allocation,
                        .heap = h,
                        .size = size,
                    };
                } else if (empty_heap_index == null) {
                    empty_heap_index = index;
                }
            }

            // couldn't allocate, use the empty heap if we got one
            const heap = try self.addHeap(memblock_size, false, empty_heap_index);
            const allocation = try heap.gpu_allocator.allocate(@intCast(size));
            return GroupAllocation{
                .allocation = allocation,
                .heap = heap,
                .size = size,
            };
        }

        fn allocateDedicated(self: *MemoryGroup, size: u64) gpu_allocator.Error!GroupAllocation {
            const memory_block = try self.addHeap(size, true, blk: {
                for (self.heaps.items, 0..) |heap, index| {
                    if (heap == null) break :blk index;
                }
                break :blk null;
            });
            const allocation = try memory_block.gpu_allocator.allocate(@intCast(size));
            return GroupAllocation{
                .allocation = allocation,
                .heap = memory_block,
                .size = size,
            };
        }

        pub fn free(self: *MemoryGroup, allocation: GroupAllocation) gpu_allocator.Error!void {
            const heap = allocation.heap;
            try heap.gpu_allocator.free(allocation.allocation);

            if (heap.gpu_allocator.isEmpty()) {
                const index = heap.index;
                heap.deinit();
                self.heaps.items[index] = null;
            }
        }

        fn addHeap(self: *MemoryGroup, size: u64, dedicated: bool, replace: ?usize) gpu_allocator.Error!*MemoryHeap {
            const heap_index: usize = blk: {
                if (replace) |index| {
                    if (self.heaps.items[index]) |*heap| {
                        heap.deinit();
                    }
                    self.heaps.items[index] = null;
                    break :blk index;
                } else {
                    _ = try self.heaps.addOne(allocator);
                    break :blk self.heaps.items.len - 1;
                }
            };
            errdefer _ = self.heaps.popOrNull();

            const heap = &self.heaps.items[heap_index].?;
            heap.* = try MemoryHeap.init(
                self,
                heap_index,
                size,
                dedicated,
            );
            return heap;
        }
    };

    pub const Allocation = struct {
        allocation: gpu_allocator.Allocation,
        heap: *MemoryHeap,
        size: u64,
        group: *MemoryGroup,
    };

    pub fn init(self: *MemoryAllocator, device: *Device) !void {
        const HeapType = struct {
            location: MemoryLocation,
            properties: c.D3D12_HEAP_PROPERTIES,
        };
        const heap_types = [_]HeapType{ .{
            .location = .gpu_only,
            .properties = c.D3D12_HEAP_PROPERTIES{
                .Type = c.D3D12_HEAP_TYPE_DEFAULT,
                .CPUPageProperty = c.D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
                .MemoryPoolPreference = c.D3D12_MEMORY_POOL_UNKNOWN,
                .CreationNodeMask = 0,
                .VisibleNodeMask = 0,
            },
        }, .{
            .location = .cpu_to_gpu,
            .properties = c.D3D12_HEAP_PROPERTIES{
                .Type = c.D3D12_HEAP_TYPE_CUSTOM,
                .CPUPageProperty = c.D3D12_CPU_PAGE_PROPERTY_WRITE_COMBINE,
                .MemoryPoolPreference = c.D3D12_MEMORY_POOL_L0,
                .CreationNodeMask = 0,
                .VisibleNodeMask = 0,
            },
        }, .{
            .location = .gpu_to_cpu,
            .properties = c.D3D12_HEAP_PROPERTIES{
                .Type = c.D3D12_HEAP_TYPE_CUSTOM,
                .CPUPageProperty = c.D3D12_CPU_PAGE_PROPERTY_WRITE_BACK,
                .MemoryPoolPreference = c.D3D12_MEMORY_POOL_L0,
                .CreationNodeMask = 0,
                .VisibleNodeMask = 0,
            },
        } };

        self.* = .{
            .device = device,
            .memory_groups = std.BoundedArray(MemoryGroup, max_memory_groups).init(0) catch unreachable,
            .allocation_sizes = .{},
        };

        var options: c.D3D12_FEATURE_DATA_D3D12_OPTIONS = undefined;
        const hr = device.d3d_device.lpVtbl.*.CheckFeatureSupport.?(
            device.d3d_device,
            c.D3D12_FEATURE_D3D12_OPTIONS,
            @ptrCast(&options),
            @sizeOf(c.D3D12_FEATURE_DATA_D3D12_OPTIONS),
        );
        if (hr != c.S_OK) return gpu_allocator.Error.Other;

        const tier_one_heap = options.ResourceHeapTier == c.D3D12_RESOURCE_HEAP_TIER_1;

        self.memory_groups = std.BoundedArray(MemoryGroup, max_memory_groups).init(0) catch unreachable;
        inline for (heap_types) |heap_type| {
            if (tier_one_heap) {
                self.memory_groups.appendAssumeCapacity(MemoryGroup.init(
                    self,
                    heap_type.location,
                    .buffer,
                    heap_type.properties,
                ));
                self.memory_groups.appendAssumeCapacity(MemoryGroup.init(
                    self,
                    heap_type.location,
                    .rtv_dsv_texture,
                    heap_type.properties,
                ));
                self.memory_groups.appendAssumeCapacity(MemoryGroup.init(
                    self,
                    heap_type.location,
                    .other_texture,
                    heap_type.properties,
                ));
            } else {
                self.memory_groups.appendAssumeCapacity(MemoryGroup.init(
                    self,
                    heap_type.location,
                    .all,
                    heap_type.properties,
                ));
            }
        }
    }

    pub fn deinit(self: *MemoryAllocator) void {
        for (self.memory_groups.slice()) |*group| {
            group.deinit();
        }
    }

    pub fn reportMemoryLeaks(self: *const MemoryAllocator) void {
        log.info("memory leaks:", .{});
        var total_blocks: u64 = 0;
        for (self.memory_groups.constSlice(), 0..) |mem_group, mem_group_index| {
            log.info("   memory group {} ({s}, {s}):", .{
                mem_group_index,
                @tagName(mem_group.heap_category),
                @tagName(mem_group.memory_location),
            });
            for (mem_group.heaps.items, 0..) |block, block_index| {
                if (block) |found_block| {
                    log.info("       block {}; total size: {}; allocated: {};", .{
                        block_index,
                        found_block.size,
                        found_block.gpu_allocator.getAllocated(),
                    });
                    total_blocks += 1;
                }
            }
        }
        log.info("total blocks: {}", .{total_blocks});
    }

    pub fn allocate(self: *MemoryAllocator, desc: *const AllocationCreateDescriptor) gpu_allocator.Error!Allocation {
        // TODO: handle alignment
        for (self.memory_groups.slice()) |*memory_group| {
            if (memory_group.memory_location != desc.location and desc.location != .unknown) continue;
            if (!desc.resource_category.heapUsable(memory_group.heap_category)) continue;
            const allocation = try memory_group.allocate(desc.size);
            return Allocation{
                .allocation = allocation.allocation,
                .heap = allocation.heap,
                .size = allocation.size,
                .group = memory_group,
            };
        }
        return gpu_allocator.Error.NoCompatibleMemoryFound;
    }

    pub fn free(self: *MemoryAllocator, allocation: Allocation) gpu_allocator.Error!void {
        _ = self;
        const group = allocation.group;
        try group.free(MemoryGroup.GroupAllocation{
            .allocation = allocation.allocation,
            .heap = allocation.heap,
            .size = allocation.size,
        });
    }

    pub fn createResource(self: *MemoryAllocator, desc: *const ResourceCreateDescriptor) gpu_allocator.Error!Resource {
        const d3d_device = self.device.d3d_device;
        const allocation_desc = blk: {
            var _out_allocation_info: c.D3D12_RESOURCE_ALLOCATION_INFO = undefined;
            const allocation_info = d3d_device.lpVtbl.*.GetResourceAllocationInfo.?(
                d3d_device,
                &_out_allocation_info,
                0,
                1,
                @ptrCast(desc.resource_desc),
            );
            break :blk AllocationCreateDescriptor{
                .location = desc.location,
                .size = allocation_info.*.SizeInBytes,
                .alignment = allocation_info.*.Alignment,
                .resource_category = desc.resource_category,
            };
        };

        const allocation = try self.allocate(&allocation_desc);

        var d3d_resource: ?*c.ID3D12Resource = null;
        const hr = d3d_device.lpVtbl.*.CreatePlacedResource.?(
            d3d_device,
            allocation.heap.heap,
            allocation.allocation.offset,
            desc.resource_desc,
            desc.initial_state,
            desc.clear_value,
            &c.IID_ID3D12Resource,
            @ptrCast(&d3d_resource),
        );
        if (hr != c.S_OK) return gpu_allocator.Error.Other;

        return Resource{
            .mem_allocator = self,
            .read_state = desc.initial_state,
            .allocation = allocation,
            .d3d_resource = d3d_resource.?,
            .memory_location = desc.location,
            .size = allocation.size,
        };
    }

    pub fn destroyResource(self: *MemoryAllocator, resource: Resource) gpu_allocator.Error!void {
        if (resource.allocation) |allocation| {
            try self.free(allocation);
        }
        const d3d_resource = resource.d3d_resource;
        _ = d3d_resource.lpVtbl.*.Release.?(d3d_resource);
    }
};

const DescriptorAllocation = struct {
    index: u32,
};

const DescriptorHeap = struct {
    // Initial version supports fixed-block size allocation only
    device: *Device,
    d3d_heap: *c.ID3D12DescriptorHeap,
    cpu_base: c.D3D12_CPU_DESCRIPTOR_HANDLE,
    gpu_base: c.D3D12_GPU_DESCRIPTOR_HANDLE,
    descriptor_size: u32,
    descriptor_count: u32,
    block_size: u32,
    next_alloc: u32,
    free_blocks: std.ArrayListUnmanaged(DescriptorAllocation) = .{},

    pub fn init(
        device: *Device,
        heap_type: c.D3D12_DESCRIPTOR_HEAP_TYPE,
        flags: c.D3D12_DESCRIPTOR_HEAP_FLAGS,
        descriptor_count: u32,
        block_size: u32,
    ) !DescriptorHeap {
        const d3d_device = device.d3d_device;
        var hr: c.HRESULT = undefined;

        var d3d_heap: *c.ID3D12DescriptorHeap = undefined;
        hr = d3d_device.lpVtbl.*.CreateDescriptorHeap.?(
            d3d_device,
            &c.D3D12_DESCRIPTOR_HEAP_DESC{
                .Type = heap_type,
                .NumDescriptors = descriptor_count,
                .Flags = flags,
                .NodeMask = 0,
            },
            &c.IID_ID3D12DescriptorHeap,
            @ptrCast(&d3d_heap),
        );
        if (hr != c.S_OK) {
            return error.CreateDescriptorHeapFailed;
        }
        errdefer _ = d3d_heap.lpVtbl.*.Release.?(d3d_heap);

        const descriptor_size = d3d_device.lpVtbl.*.GetDescriptorHandleIncrementSize.?(
            d3d_device,
            heap_type,
        );

        var cpu_base: c.D3D12_CPU_DESCRIPTOR_HANDLE = undefined;
        _ = d3d_heap.lpVtbl.*.GetCPUDescriptorHandleForHeapStart.?(
            d3d_heap,
            &cpu_base,
        );

        var gpu_base: c.D3D12_GPU_DESCRIPTOR_HANDLE = undefined;
        if ((flags & c.D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE) != 0) {
            _ = d3d_heap.lpVtbl.*.GetGPUDescriptorHandleForHeapStart.?(
                d3d_heap,
                &gpu_base,
            );
        } else {
            gpu_base = .{ .ptr = 0 };
        }

        return .{
            .device = device,
            .d3d_heap = d3d_heap,
            .cpu_base = cpu_base,
            .gpu_base = gpu_base,
            .descriptor_size = descriptor_size,
            .descriptor_count = descriptor_count,
            .block_size = block_size,
            .next_alloc = 0,
        };
    }

    pub fn deinit(heap: *DescriptorHeap) void {
        const d3d_heap = heap.d3d_heap;

        heap.free_blocks.deinit(allocator);
        _ = d3d_heap.lpVtbl.*.Release.?(d3d_heap);
    }

    pub fn alloc(heap: *DescriptorHeap) !DescriptorAllocation {
        // Recycle finished blocks
        if (heap.free_blocks.items.len == 0) {
            heap.device.processQueuedOperations();
        }

        // Create new block
        if (heap.free_blocks.items.len == 0) {
            if (heap.next_alloc == heap.descriptor_count)
                return error.OutOfDescriptorMemory;

            const index = heap.next_alloc;
            heap.next_alloc += heap.block_size;
            try heap.free_blocks.append(allocator, .{ .index = index });
        }

        // Result
        return heap.free_blocks.pop();
    }

    pub fn free(heap: *DescriptorHeap, allocation: DescriptorAllocation) void {
        heap.free_blocks.append(allocator, allocation) catch {
            std.debug.panic("OutOfMemory", .{});
        };
    }

    pub fn cpuDescriptor(heap: *DescriptorHeap, index: u32) c.D3D12_CPU_DESCRIPTOR_HANDLE {
        return .{ .ptr = heap.cpu_base.ptr + index * heap.descriptor_size };
    }

    pub fn gpuDescriptor(heap: *DescriptorHeap, index: u32) c.D3D12_GPU_DESCRIPTOR_HANDLE {
        return .{ .ptr = heap.gpu_base.ptr + index * heap.descriptor_size };
    }
};

const CommandManager = struct {
    device: *Device,
    free_allocators: std.ArrayListUnmanaged(*c.ID3D12CommandAllocator) = .{},
    free_command_lists: std.ArrayListUnmanaged(*c.ID3D12GraphicsCommandList) = .{},

    pub fn init(device: *Device) CommandManager {
        return .{
            .device = device,
        };
    }

    pub fn deinit(manager: *CommandManager) void {
        for (manager.free_allocators.items) |command_allocator| {
            _ = command_allocator.lpVtbl.*.Release.?(command_allocator);
        }
        for (manager.free_command_lists.items) |command_list| {
            _ = command_list.lpVtbl.*.Release.?(command_list);
        }

        manager.free_allocators.deinit(allocator);
        manager.free_command_lists.deinit(allocator);
    }

    pub fn createCommandAllocator(manager: *CommandManager) !*c.ID3D12CommandAllocator {
        const d3d_device = manager.device.d3d_device;
        var hr: c.HRESULT = undefined;

        // Recycle finished allocators
        if (manager.free_allocators.items.len == 0) {
            manager.device.processQueuedOperations();
        }

        // Create new command allocator
        if (manager.free_allocators.items.len == 0) {
            var command_allocator: *c.ID3D12CommandAllocator = undefined;
            hr = d3d_device.lpVtbl.*.CreateCommandAllocator.?(
                d3d_device,
                c.D3D12_COMMAND_LIST_TYPE_DIRECT,
                &c.IID_ID3D12CommandAllocator,
                @ptrCast(&command_allocator),
            );
            if (hr != c.S_OK) {
                return error.CreateCommandAllocatorFailed;
            }

            try manager.free_allocators.append(allocator, command_allocator);
        }

        // Reset
        const command_allocator = manager.free_allocators.pop();
        hr = command_allocator.lpVtbl.*.Reset.?(command_allocator);
        if (hr != c.S_OK) {
            return error.ResetCommandAllocatorFailed;
        }
        return command_allocator;
    }

    pub fn destroyCommandAllocator(manager: *CommandManager, command_allocator: *c.ID3D12CommandAllocator) void {
        manager.free_allocators.append(allocator, command_allocator) catch {
            std.debug.panic("OutOfMemory", .{});
        };
    }

    pub fn createCommandList(
        manager: *CommandManager,
        command_allocator: *c.ID3D12CommandAllocator,
    ) !*c.ID3D12GraphicsCommandList {
        const d3d_device = manager.device.d3d_device;
        var hr: c.HRESULT = undefined;

        if (manager.free_command_lists.items.len == 0) {
            var command_list: *c.ID3D12GraphicsCommandList = undefined;
            hr = d3d_device.lpVtbl.*.CreateCommandList.?(
                d3d_device,
                0,
                c.D3D12_COMMAND_LIST_TYPE_DIRECT,
                command_allocator,
                null,
                &c.IID_ID3D12GraphicsCommandList,
                @ptrCast(&command_list),
            );
            if (hr != c.S_OK) {
                return error.CreateCommandListFailed;
            }

            return command_list;
        }

        const command_list = manager.free_command_lists.pop();
        hr = command_list.lpVtbl.*.Reset.?(
            command_list,
            command_allocator,
            null,
        );
        if (hr != c.S_OK) {
            return error.ResetCommandListFailed;
        }

        return command_list;
    }

    pub fn destroyCommandList(manager: *CommandManager, command_list: *c.ID3D12GraphicsCommandList) void {
        manager.free_command_lists.append(allocator, command_list) catch std.debug.panic("OutOfMemory", .{});
    }
};

pub const StreamingManager = struct {
    device: *Device,
    free_buffers: std.ArrayListUnmanaged(Resource) = .{},

    pub fn init(device: *Device) !StreamingManager {
        return .{
            .device = device,
        };
    }

    pub fn deinit(manager: *StreamingManager) void {
        for (manager.free_buffers.items) |*d3d_resource| {
            d3d_resource.deinit();
        }
        manager.free_buffers.deinit(allocator);
    }

    pub fn acquire(manager: *StreamingManager) !Resource {
        const device = manager.device;

        // Recycle finished buffers
        if (manager.free_buffers.items.len == 0) {
            device.processQueuedOperations();
        }

        // Create new buffer
        if (manager.free_buffers.items.len == 0) {
            var resource = try device.createD3dBuffer(.{ .map_write = true }, upload_page_size);
            errdefer _ = resource.deinit();

            setDebugName(@ptrCast(resource.d3d_resource), "upload");
            try manager.free_buffers.append(allocator, resource);
        }

        // Result
        return manager.free_buffers.pop();
    }

    pub fn release(manager: *StreamingManager, resource: Resource) void {
        manager.free_buffers.append(allocator, resource) catch {
            std.debug.panic("OutOfMemory", .{});
        };
    }
};

pub const SwapChain = struct {
    manager: utils.Manager(SwapChain) = .{},
    device: *Device,
    surface: *Surface,
    queue: *Queue,
    dxgi_swap_chain: *c.IDXGISwapChain3,
    width: u32,
    height: u32,
    back_buffer_count: u32,
    sync_interval: c.UINT,
    present_flags: c.UINT,
    textures: [max_back_buffer_count]*Texture,
    views: [max_back_buffer_count]*TextureView,
    fence_values: [max_back_buffer_count]u64,
    buffer_index: u32 = 0,

    pub fn init(device: *Device, surface: *Surface, desc: *const sysgpu.SwapChain.Descriptor) !*SwapChain {
        const instance = device.adapter.instance;
        const dxgi_factory = instance.dxgi_factory;
        var hr: c.HRESULT = undefined;

        device.processQueuedOperations();

        // Swap Chain
        const back_buffer_count: u32 = if (desc.present_mode == .mailbox) 3 else 2;
        var swap_chain_desc = c.DXGI_SWAP_CHAIN_DESC1{
            .Width = desc.width,
            .Height = desc.height,
            .Format = conv.dxgiFormatForTexture(desc.format),
            .Stereo = c.FALSE,
            .SampleDesc = .{ .Count = 1, .Quality = 0 },
            .BufferUsage = conv.dxgiUsage(desc.usage),
            .BufferCount = back_buffer_count,
            .Scaling = c.DXGI_MODE_SCALING_UNSPECIFIED,
            .SwapEffect = c.DXGI_SWAP_EFFECT_FLIP_DISCARD,
            .AlphaMode = c.DXGI_ALPHA_MODE_UNSPECIFIED,
            .Flags = if (instance.allow_tearing) c.DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING else 0,
        };

        var dxgi_swap_chain: *c.IDXGISwapChain3 = undefined;
        hr = dxgi_factory.lpVtbl.*.CreateSwapChainForHwnd.?(
            dxgi_factory,
            @ptrCast(device.queue.d3d_command_queue),
            surface.hwnd,
            &swap_chain_desc,
            null,
            null,
            @ptrCast(&dxgi_swap_chain),
        );
        if (hr != c.S_OK) {
            return error.CreateSwapChainFailed;
        }
        errdefer _ = dxgi_swap_chain.lpVtbl.*.Release.?(dxgi_swap_chain);

        // Views
        var textures = std.BoundedArray(*Texture, max_back_buffer_count){};
        var views = std.BoundedArray(*TextureView, max_back_buffer_count){};
        var fence_values = std.BoundedArray(u64, max_back_buffer_count){};
        errdefer {
            for (views.slice()) |view| view.manager.release();
            for (textures.slice()) |texture| texture.manager.release();
        }

        for (0..back_buffer_count) |i| {
            var buffer: *c.ID3D12Resource = undefined;
            hr = dxgi_swap_chain.lpVtbl.*.GetBuffer.?(
                dxgi_swap_chain,
                @intCast(i),
                &c.IID_ID3D12Resource,
                @ptrCast(&buffer),
            );
            if (hr != c.S_OK) {
                return error.SwapChainGetBufferFailed;
            }

            const texture = try Texture.initForSwapChain(device, desc, buffer);
            const view = try texture.createView(&sysgpu.TextureView.Descriptor{});

            textures.appendAssumeCapacity(texture);
            views.appendAssumeCapacity(view);
            fence_values.appendAssumeCapacity(0);
        }

        // Result
        const swapchain = try allocator.create(SwapChain);
        swapchain.* = .{
            .device = device,
            .surface = surface,
            .queue = device.queue,
            .dxgi_swap_chain = dxgi_swap_chain,
            .width = desc.width,
            .height = desc.height,
            .back_buffer_count = back_buffer_count,
            .sync_interval = if (desc.present_mode == .immediate) 0 else 1,
            .present_flags = if (desc.present_mode == .immediate and instance.allow_tearing) DXGI_PRESENT_ALLOW_TEARING else 0,
            .textures = textures.buffer,
            .views = views.buffer,
            .fence_values = fence_values.buffer,
        };
        return swapchain;
    }

    pub fn deinit(swapchain: *SwapChain) void {
        const dxgi_swap_chain = swapchain.dxgi_swap_chain;
        const queue = swapchain.queue;

        queue.waitUntil(queue.fence_value);

        for (swapchain.views[0..swapchain.back_buffer_count]) |view| view.manager.release();
        for (swapchain.textures[0..swapchain.back_buffer_count]) |texture| texture.manager.release();
        _ = dxgi_swap_chain.lpVtbl.*.Release.?(dxgi_swap_chain);
        allocator.destroy(swapchain);
    }

    pub fn getCurrentTextureView(swapchain: *SwapChain) !*TextureView {
        const dxgi_swap_chain = swapchain.dxgi_swap_chain;

        const fence_value = swapchain.fence_values[swapchain.buffer_index];
        swapchain.queue.waitUntil(fence_value);

        const index = dxgi_swap_chain.lpVtbl.*.GetCurrentBackBufferIndex.?(dxgi_swap_chain);
        swapchain.buffer_index = index;
        // TEMP - resolve reference tracking in main.zig
        swapchain.views[index].manager.reference();
        return swapchain.views[index];
    }

    pub fn present(swapchain: *SwapChain) !void {
        const dxgi_swap_chain = swapchain.dxgi_swap_chain;
        const queue = swapchain.queue;
        var hr: c.HRESULT = undefined;

        hr = dxgi_swap_chain.lpVtbl.*.Present.?(
            dxgi_swap_chain,
            swapchain.sync_interval,
            swapchain.present_flags,
        );
        if (hr != c.S_OK) {
            return error.PresentFailed;
        }

        queue.fence_value += 1;
        try queue.signal();
        swapchain.fence_values[swapchain.buffer_index] = queue.fence_value;
    }
};

pub const Resource = struct {
    // NOTE - this is a naive sync solution as a placeholder until render graphs are implemented

    mem_allocator: ?*MemoryAllocator = null,
    read_state: c.D3D12_RESOURCE_STATES,
    allocation: ?MemoryAllocator.Allocation = null,
    d3d_resource: *c.ID3D12Resource,
    memory_location: MemoryLocation = .unknown,
    size: u64 = 0,

    pub fn init(
        d3d_resource: *c.ID3D12Resource,
        read_state: c.D3D12_RESOURCE_STATES,
    ) Resource {
        return .{
            .d3d_resource = d3d_resource,
            .read_state = read_state,
        };
    }

    pub fn deinit(resource: *Resource) void {
        if (resource.mem_allocator) |mem_allocator| {
            mem_allocator.destroyResource(resource.*) catch {};
        }
    }
};

pub const Buffer = struct {
    manager: utils.Manager(Buffer) = .{},
    device: *Device,
    resource: Resource,
    stage_buffer: ?*Buffer,
    gpu_count: u32 = 0,
    map: ?[*]u8,
    // TODO - packed buffer descriptor struct
    size: u64,
    usage: sysgpu.Buffer.UsageFlags,

    pub fn init(device: *Device, desc: *const sysgpu.Buffer.Descriptor) !*Buffer {
        var hr: c.HRESULT = undefined;

        var resource = try device.createD3dBuffer(desc.usage, desc.size);
        errdefer resource.deinit();

        if (desc.label) |label|
            setDebugName(@ptrCast(resource.d3d_resource), label);

        // Mapped at Creation
        var stage_buffer: ?*Buffer = null;
        var map: ?*anyopaque = null;
        if (desc.mapped_at_creation == .true) {
            var map_resource: *c.ID3D12Resource = undefined;
            if (!desc.usage.map_write) {
                stage_buffer = try Buffer.init(device, &.{
                    .usage = .{ .copy_src = true, .map_write = true },
                    .size = desc.size,
                });
                map_resource = stage_buffer.?.resource.d3d_resource;
            } else {
                map_resource = resource.d3d_resource;
            }

            // TODO - map status in callback instead of failure
            hr = map_resource.lpVtbl.*.Map.?(map_resource, 0, null, &map);
            if (hr != c.S_OK) {
                return error.MapBufferAtCreationFailed;
            }
        }

        // Result
        const buffer = try allocator.create(Buffer);
        buffer.* = .{
            .device = device,
            .resource = resource,
            .stage_buffer = stage_buffer,
            .map = @ptrCast(map),
            .size = desc.size,
            .usage = desc.usage,
        };
        return buffer;
    }

    pub fn deinit(buffer: *Buffer) void {
        if (buffer.stage_buffer) |stage_buffer| stage_buffer.manager.release();
        buffer.resource.deinit();
        allocator.destroy(buffer);
    }

    pub fn getMappedRange(buffer: *Buffer, offset: usize, size: usize) !?*anyopaque {
        return @ptrCast(buffer.map.?[offset .. offset + size]);
    }

    pub fn getSize(buffer: *Buffer) u64 {
        return buffer.size;
    }

    pub fn getUsage(buffer: *Buffer) sysgpu.Buffer.UsageFlags {
        return buffer.usage;
    }

    pub fn mapAsync(
        buffer: *Buffer,
        mode: sysgpu.MapModeFlags,
        offset: usize,
        size: usize,
        callback: sysgpu.Buffer.MapCallback,
        userdata: ?*anyopaque,
    ) !void {
        _ = size;
        _ = offset;
        _ = mode;

        const map_callback = MapCallback{ .buffer = buffer, .callback = callback, .userdata = userdata };
        if (buffer.gpu_count == 0) {
            buffer.executeMapAsync(map_callback);
        } else {
            try buffer.device.map_callbacks.append(allocator, map_callback);
        }
    }

    pub fn setLabel(buffer: *Buffer, label: [*:0]const u8) void {
        setDebugName(@ptrCast(buffer.resource.d3d_resource), label);
    }

    pub fn unmap(buffer: *Buffer) !void {
        var map_resource: *c.ID3D12Resource = undefined;
        if (buffer.stage_buffer) |stage_buffer| {
            map_resource = stage_buffer.resource.d3d_resource;
            const encoder = try buffer.device.queue.getCommandEncoder();
            try encoder.copyBufferToBuffer(stage_buffer, 0, buffer, 0, buffer.size);
            stage_buffer.manager.release();
            buffer.stage_buffer = null;
        } else {
            map_resource = buffer.resource.d3d_resource;
        }
        map_resource.lpVtbl.*.Unmap.?(map_resource, 0, null);
    }

    // Internal
    pub fn executeMapAsync(buffer: *Buffer, map_callback: MapCallback) void {
        const d3d_resource = buffer.resource.d3d_resource;
        var hr: c.HRESULT = undefined;

        var map: ?*anyopaque = null;
        hr = d3d_resource.lpVtbl.*.Map.?(d3d_resource, 0, null, &map);
        if (hr != c.S_OK) {
            map_callback.callback(.unknown, map_callback.userdata);
            return;
        }

        buffer.map = @ptrCast(map);
        map_callback.callback(.success, map_callback.userdata);
    }
};

pub const Texture = struct {
    manager: utils.Manager(Texture) = .{},
    device: *Device,
    resource: Resource,
    // TODO - packed texture descriptor struct
    usage: sysgpu.Texture.UsageFlags,
    dimension: sysgpu.Texture.Dimension,
    size: sysgpu.Extent3D,
    format: sysgpu.Texture.Format,
    mip_level_count: u32,
    sample_count: u32,

    pub fn init(device: *Device, desc: *const sysgpu.Texture.Descriptor) !*Texture {
        const resource_desc = c.D3D12_RESOURCE_DESC{
            .Dimension = conv.d3d12ResourceDimension(desc.dimension),
            .Alignment = 0,
            .Width = desc.size.width,
            .Height = desc.size.height,
            .DepthOrArraySize = @intCast(desc.size.depth_or_array_layers),
            .MipLevels = @intCast(desc.mip_level_count),
            .Format = conv.dxgiFormatForTextureResource(desc.format, desc.usage, desc.view_format_count),
            .SampleDesc = .{ .Count = desc.sample_count, .Quality = 0 },
            .Layout = c.D3D12_TEXTURE_LAYOUT_UNKNOWN,
            .Flags = conv.d3d12ResourceFlagsForTexture(desc.usage, desc.format),
        };
        const read_state = conv.d3d12ResourceStatesForTextureRead(desc.usage);
        const initial_state = read_state;

        const clear_value = c.D3D12_CLEAR_VALUE{ .Format = resource_desc.Format };

        // TODO: the code below was terribly broken, I rewrote it, Is it correct?
        // const create_desc = ResourceCreateDescriptor{
        //     .location = .gpu_only,
        //     .resource_desc = if (utils.formatHasDepthOrStencil(desc.format) or desc.usage.render_attachment)
        //         &clear_value
        //     else
        //         null,
        //     .clear_value = null,
        //     .resource_category = .buffer,
        //     .initial_state = initial_state,
        // };
        const create_desc = ResourceCreateDescriptor{
            .location = .gpu_only,
            .resource_desc = &resource_desc,
            .clear_value = if (utils.formatHasDepthOrStencil(desc.format) or desc.usage.render_attachment)
                &clear_value
            else
                null,
            .resource_category = .buffer,
            .initial_state = initial_state,
        };
        const resource = device.mem_allocator.createResource(&create_desc) catch
            return error.CreateTextureFailed;

        if (desc.label) |label|
            setDebugName(@ptrCast(resource.d3d_resource), label);

        // Result
        const texture = try allocator.create(Texture);
        texture.* = .{
            .device = device,
            .resource = resource,
            .usage = desc.usage,
            .dimension = desc.dimension,
            .size = desc.size,
            .format = desc.format,
            .mip_level_count = desc.mip_level_count,
            .sample_count = desc.sample_count,
        };
        return texture;
    }

    pub fn initForSwapChain(device: *Device, desc: *const sysgpu.SwapChain.Descriptor, d3d_resource: *c.ID3D12Resource) !*Texture {
        const read_state = c.D3D12_RESOURCE_STATE_PRESENT;

        const texture = try allocator.create(Texture);
        texture.* = .{
            .device = device,
            .resource = Resource.init(d3d_resource, read_state),
            .usage = desc.usage,
            .dimension = .dimension_2d,
            .size = .{ .width = desc.width, .height = desc.height, .depth_or_array_layers = 1 },
            .format = desc.format,
            .mip_level_count = 1,
            .sample_count = 1,
        };
        return texture;
    }

    pub fn deinit(texture: *Texture) void {
        texture.resource.deinit();
        allocator.destroy(texture);
    }

    pub fn createView(texture: *Texture, desc: *const sysgpu.TextureView.Descriptor) !*TextureView {
        return TextureView.init(texture, desc);
    }

    // Internal
    pub fn calcSubresource(texture: *Texture, mip_level: u32, array_slice: u32) u32 {
        return mip_level + (array_slice * texture.mip_level_count);
    }
};

pub const TextureView = struct {
    manager: utils.Manager(TextureView) = .{},
    texture: *Texture,
    format: sysgpu.Texture.Format,
    dimension: sysgpu.TextureView.Dimension,
    base_mip_level: u32,
    mip_level_count: u32,
    base_array_layer: u32,
    array_layer_count: u32,
    aspect: sysgpu.Texture.Aspect,
    base_subresource: u32,

    pub fn init(texture: *Texture, desc: *const sysgpu.TextureView.Descriptor) !*TextureView {
        texture.manager.reference();

        const texture_dimension: sysgpu.TextureView.Dimension = switch (texture.dimension) {
            .dimension_1d => .dimension_1d,
            .dimension_2d => .dimension_2d,
            .dimension_3d => .dimension_3d,
        };

        const view = try allocator.create(TextureView);
        view.* = .{
            .texture = texture,
            .format = if (desc.format != .undefined) desc.format else texture.format,
            .dimension = if (desc.dimension != .dimension_undefined) desc.dimension else texture_dimension,
            .base_mip_level = desc.base_mip_level,
            .mip_level_count = desc.mip_level_count,
            .base_array_layer = desc.base_array_layer,
            .array_layer_count = desc.array_layer_count,
            .aspect = desc.aspect,
            .base_subresource = texture.calcSubresource(desc.base_mip_level, desc.base_array_layer),
        };
        return view;
    }

    pub fn deinit(view: *TextureView) void {
        view.texture.manager.release();
        allocator.destroy(view);
    }

    // Internal
    pub fn width(view: *TextureView) u32 {
        return @max(1, view.texture.size.width >> @intCast(view.base_mip_level));
    }

    pub fn height(view: *TextureView) u32 {
        return @max(1, view.texture.size.height >> @intCast(view.base_mip_level));
    }

    pub fn srvDesc(view: *TextureView) c.D3D12_SHADER_RESOURCE_VIEW_DESC {
        var srv_desc: c.D3D12_SHADER_RESOURCE_VIEW_DESC = undefined;
        srv_desc.Format = conv.dxgiFormatForTextureView(view.format, view.aspect);
        srv_desc.ViewDimension = conv.d3d12SrvDimension(view.dimension, view.texture.sample_count);
        srv_desc.Shader4ComponentMapping = c.D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
        switch (srv_desc.ViewDimension) {
            c.D3D12_SRV_DIMENSION_TEXTURE1D => srv_desc.unnamed_0.Texture1D = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .ResourceMinLODClamp = 0.0,
            },
            c.D3D12_SRV_DIMENSION_TEXTURE2D => srv_desc.unnamed_0.Texture2D = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .PlaneSlice = 0, // TODO
                .ResourceMinLODClamp = 0.0,
            },
            c.D3D12_SRV_DIMENSION_TEXTURE2DARRAY => srv_desc.unnamed_0.Texture2DArray = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .FirstArraySlice = view.base_array_layer,
                .ArraySize = view.array_layer_count,
                .PlaneSlice = 0,
                .ResourceMinLODClamp = 0.0,
            },
            c.D3D12_SRV_DIMENSION_TEXTURE2DMS => {},
            c.D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY => srv_desc.unnamed_0.Texture2DMSArray = .{
                .FirstArraySlice = view.base_array_layer,
                .ArraySize = view.array_layer_count,
            },
            c.D3D12_SRV_DIMENSION_TEXTURE3D => srv_desc.unnamed_0.Texture3D = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .ResourceMinLODClamp = 0.0,
            },
            c.D3D12_SRV_DIMENSION_TEXTURECUBE => srv_desc.unnamed_0.TextureCube = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .ResourceMinLODClamp = 0.0,
            },
            c.D3D12_SRV_DIMENSION_TEXTURECUBEARRAY => srv_desc.unnamed_0.TextureCubeArray = .{
                .MostDetailedMip = view.base_mip_level,
                .MipLevels = view.mip_level_count,
                .First2DArrayFace = view.base_array_layer, // TODO - does this need a conversion?
                .NumCubes = view.array_layer_count, // TODO - does this need a conversion?
                .ResourceMinLODClamp = 0.0,
            },
            else => {},
        }
        return srv_desc;
    }

    pub fn uavDesc(view: *TextureView) c.D3D12_UNORDERED_ACCESS_VIEW_DESC {
        var uav_desc: c.D3D12_UNORDERED_ACCESS_VIEW_DESC = undefined;
        uav_desc.Format = conv.dxgiFormatForTextureView(view.format, view.aspect);
        uav_desc.ViewDimension = conv.d3d12UavDimension(view.dimension);
        switch (uav_desc.ViewDimension) {
            c.D3D12_UAV_DIMENSION_TEXTURE1D => uav_desc.unnamed_0.Texture1D = .{
                .MipSlice = view.base_mip_level,
            },
            c.D3D12_UAV_DIMENSION_TEXTURE2D => uav_desc.unnamed_0.Texture2D = .{
                .MipSlice = view.base_mip_level,
                .PlaneSlice = 0, // TODO
            },
            c.D3D12_UAV_DIMENSION_TEXTURE2DARRAY => uav_desc.unnamed_0.Texture2DArray = .{
                .MipSlice = view.base_mip_level,
                .FirstArraySlice = view.base_array_layer,
                .ArraySize = view.array_layer_count,
                .PlaneSlice = 0,
            },
            c.D3D12_UAV_DIMENSION_TEXTURE3D => uav_desc.unnamed_0.Texture3D = .{
                .MipSlice = view.base_mip_level,
                .FirstWSlice = view.base_array_layer, // TODO - ??
                .WSize = view.array_layer_count, // TODO - ??
            },
            else => {},
        }
        return uav_desc;
    }
};

pub const Sampler = struct {
    manager: utils.Manager(Sampler) = .{},
    d3d_desc: c.D3D12_SAMPLER_DESC,

    pub fn init(device: *Device, desc: *const sysgpu.Sampler.Descriptor) !*Sampler {
        _ = device;

        const d3d_desc = c.D3D12_SAMPLER_DESC{
            .Filter = conv.d3d12Filter(desc.mag_filter, desc.min_filter, desc.mipmap_filter, desc.max_anisotropy),
            .AddressU = conv.d3d12TextureAddressMode(desc.address_mode_u),
            .AddressV = conv.d3d12TextureAddressMode(desc.address_mode_v),
            .AddressW = conv.d3d12TextureAddressMode(desc.address_mode_w),
            .MipLODBias = 0.0,
            .MaxAnisotropy = desc.max_anisotropy,
            .ComparisonFunc = if (desc.compare != .undefined) conv.d3d12ComparisonFunc(desc.compare) else c.D3D12_COMPARISON_FUNC_NEVER,
            .BorderColor = [4]c.FLOAT{ 0.0, 0.0, 0.0, 0.0 },
            .MinLOD = desc.lod_min_clamp,
            .MaxLOD = desc.lod_max_clamp,
        };

        const sampler = try allocator.create(Sampler);
        sampler.* = .{
            .d3d_desc = d3d_desc,
        };
        return sampler;
    }

    pub fn deinit(sampler: *Sampler) void {
        allocator.destroy(sampler);
    }
};

pub const BindGroupLayout = struct {
    const Entry = struct {
        binding: u32,
        visibility: sysgpu.ShaderStageFlags,
        buffer: sysgpu.Buffer.BindingLayout = .{},
        sampler: sysgpu.Sampler.BindingLayout = .{},
        texture: sysgpu.Texture.BindingLayout = .{},
        storage_texture: sysgpu.StorageTextureBindingLayout = .{},
        range_type: c.D3D12_DESCRIPTOR_RANGE_TYPE,
        table_index: ?u32,
        dynamic_index: ?u32,
    };

    const DynamicEntry = struct {
        parameter_type: c.D3D12_ROOT_PARAMETER_TYPE,
    };

    manager: utils.Manager(BindGroupLayout) = .{},
    entries: std.ArrayListUnmanaged(Entry),
    dynamic_entries: std.ArrayListUnmanaged(DynamicEntry),
    general_table_size: u32,
    sampler_table_size: u32,

    pub fn init(device: *Device, desc: *const sysgpu.BindGroupLayout.Descriptor) !*BindGroupLayout {
        _ = device;

        var entries = std.ArrayListUnmanaged(Entry){};
        errdefer entries.deinit(allocator);

        var dynamic_entries = std.ArrayListUnmanaged(DynamicEntry){};
        errdefer dynamic_entries.deinit(allocator);

        var general_table_size: u32 = 0;
        var sampler_table_size: u32 = 0;
        for (0..desc.entry_count) |entry_index| {
            const entry = desc.entries.?[entry_index];

            var table_index: ?u32 = null;
            var dynamic_index: ?u32 = null;
            if (entry.buffer.has_dynamic_offset == .true) {
                dynamic_index = @intCast(dynamic_entries.items.len);
                try dynamic_entries.append(allocator, .{
                    .parameter_type = conv.d3d12RootParameterType(entry),
                });
            } else if (entry.sampler.type != .undefined) {
                table_index = sampler_table_size;
                sampler_table_size += 1;
            } else {
                table_index = general_table_size;
                general_table_size += 1;
            }

            try entries.append(allocator, .{
                .binding = entry.binding,
                .visibility = entry.visibility,
                .buffer = entry.buffer,
                .sampler = entry.sampler,
                .texture = entry.texture,
                .storage_texture = entry.storage_texture,
                .range_type = conv.d3d12DescriptorRangeType(entry),
                .table_index = table_index,
                .dynamic_index = dynamic_index,
            });
        }

        const layout = try allocator.create(BindGroupLayout);
        layout.* = .{
            .entries = entries,
            .dynamic_entries = dynamic_entries,
            .general_table_size = general_table_size,
            .sampler_table_size = sampler_table_size,
        };
        return layout;
    }

    pub fn deinit(layout: *BindGroupLayout) void {
        layout.entries.deinit(allocator);
        layout.dynamic_entries.deinit(allocator);
        allocator.destroy(layout);
    }

    // Internal
    pub fn getEntry(layout: *BindGroupLayout, binding: u32) ?*const Entry {
        for (layout.entries.items) |*entry| {
            if (entry.binding == binding)
                return entry;
        }

        return null;
    }
};

pub const BindGroup = struct {
    const ResourceAccess = struct {
        resource: *Resource,
        uav: bool,
    };
    const DynamicResource = struct {
        address: c.D3D12_GPU_VIRTUAL_ADDRESS,
        parameter_type: c.D3D12_ROOT_PARAMETER_TYPE,
    };

    manager: utils.Manager(BindGroup) = .{},
    device: *Device,
    general_allocation: ?DescriptorAllocation,
    general_table: ?c.D3D12_GPU_DESCRIPTOR_HANDLE,
    sampler_allocation: ?DescriptorAllocation,
    sampler_table: ?c.D3D12_GPU_DESCRIPTOR_HANDLE,
    dynamic_resources: []DynamicResource,
    buffers: std.ArrayListUnmanaged(*Buffer),
    textures: std.ArrayListUnmanaged(*Texture),
    accesses: std.ArrayListUnmanaged(ResourceAccess),

    pub fn init(device: *Device, desc: *const sysgpu.BindGroup.Descriptor) !*BindGroup {
        const d3d_device = device.d3d_device;

        const layout: *BindGroupLayout = @ptrCast(@alignCast(desc.layout));

        // General Descriptor Table
        var general_allocation: ?DescriptorAllocation = null;
        var general_table: ?c.D3D12_GPU_DESCRIPTOR_HANDLE = null;

        if (layout.general_table_size > 0) {
            const allocation = try device.general_heap.alloc();
            general_allocation = allocation;
            general_table = device.general_heap.gpuDescriptor(allocation.index);

            for (0..desc.entry_count) |i| {
                const entry = desc.entries.?[i];
                const layout_entry = layout.getEntry(entry.binding) orelse return error.UnknownBinding;
                if (layout_entry.sampler.type != .undefined)
                    continue;

                if (layout_entry.table_index) |table_index| {
                    const dest_descriptor = device.general_heap.cpuDescriptor(allocation.index + table_index);

                    if (layout_entry.buffer.type != .undefined) {
                        const buffer: *Buffer = @ptrCast(@alignCast(entry.buffer.?));
                        const d3d_resource = buffer.resource.d3d_resource;

                        const buffer_location = d3d_resource.lpVtbl.*.GetGPUVirtualAddress.?(d3d_resource) + entry.offset;

                        switch (layout_entry.buffer.type) {
                            .undefined => unreachable,
                            .uniform => {
                                const cbv_desc: c.D3D12_CONSTANT_BUFFER_VIEW_DESC = .{
                                    .BufferLocation = buffer_location,
                                    .SizeInBytes = @intCast(utils.alignUp(entry.size, limits.min_uniform_buffer_offset_alignment)),
                                };

                                d3d_device.lpVtbl.*.CreateConstantBufferView.?(
                                    d3d_device,
                                    &cbv_desc,
                                    dest_descriptor,
                                );
                            },
                            .storage => {
                                // TODO - switch to RWByteAddressBuffer after using DXC
                                const stride = entry.elem_size;
                                const uav_desc: c.D3D12_UNORDERED_ACCESS_VIEW_DESC = .{
                                    .Format = c.DXGI_FORMAT_UNKNOWN,
                                    .ViewDimension = c.D3D12_UAV_DIMENSION_BUFFER,
                                    .unnamed_0 = .{
                                        .Buffer = .{
                                            .FirstElement = @intCast(entry.offset / stride),
                                            .NumElements = @intCast(entry.size / stride),
                                            .StructureByteStride = stride,
                                            .CounterOffsetInBytes = 0,
                                            .Flags = 0,
                                        },
                                    },
                                };

                                d3d_device.lpVtbl.*.CreateUnorderedAccessView.?(
                                    d3d_device,
                                    d3d_resource,
                                    null,
                                    &uav_desc,
                                    dest_descriptor,
                                );
                            },
                            .read_only_storage => {
                                // TODO - switch to ByteAddressBuffer after using DXC
                                const stride = entry.elem_size;
                                const srv_desc: c.D3D12_SHADER_RESOURCE_VIEW_DESC = .{
                                    .Format = c.DXGI_FORMAT_UNKNOWN,
                                    .ViewDimension = c.D3D12_SRV_DIMENSION_BUFFER,
                                    .Shader4ComponentMapping = c.D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING,
                                    .unnamed_0 = .{
                                        .Buffer = .{
                                            .FirstElement = @intCast(entry.offset / stride),
                                            .NumElements = @intCast(entry.size / stride),
                                            .StructureByteStride = stride,
                                            .Flags = 0,
                                        },
                                    },
                                };

                                d3d_device.lpVtbl.*.CreateShaderResourceView.?(
                                    d3d_device,
                                    d3d_resource,
                                    &srv_desc,
                                    dest_descriptor,
                                );
                            },
                        }
                    } else if (layout_entry.texture.sample_type != .undefined) {
                        const texture_view: *TextureView = @ptrCast(@alignCast(entry.texture_view.?));
                        const d3d_resource = texture_view.texture.resource.d3d_resource;

                        d3d_device.lpVtbl.*.CreateShaderResourceView.?(
                            d3d_device,
                            d3d_resource,
                            &texture_view.srvDesc(),
                            dest_descriptor,
                        );
                    } else if (layout_entry.storage_texture.format != .undefined) {
                        const texture_view: *TextureView = @ptrCast(@alignCast(entry.texture_view.?));
                        const d3d_resource = texture_view.texture.resource.d3d_resource;

                        d3d_device.lpVtbl.*.CreateUnorderedAccessView.?(
                            d3d_device,
                            d3d_resource,
                            null,
                            &texture_view.uavDesc(),
                            dest_descriptor,
                        );
                    }
                }
            }
        }

        // Sampler Descriptor Table
        var sampler_allocation: ?DescriptorAllocation = null;
        var sampler_table: ?c.D3D12_GPU_DESCRIPTOR_HANDLE = null;

        if (layout.sampler_table_size > 0) {
            const allocation = try device.sampler_heap.alloc();
            sampler_allocation = allocation;
            sampler_table = device.sampler_heap.gpuDescriptor(allocation.index);

            for (0..desc.entry_count) |i| {
                const entry = desc.entries.?[i];
                const layout_entry = layout.getEntry(entry.binding) orelse return error.UnknownBinding;
                if (layout_entry.sampler.type == .undefined)
                    continue;

                if (layout_entry.table_index) |table_index| {
                    const dest_descriptor = device.sampler_heap.cpuDescriptor(allocation.index + table_index);

                    const sampler: *Sampler = @ptrCast(@alignCast(entry.sampler.?));

                    d3d_device.lpVtbl.*.CreateSampler.?(
                        d3d_device,
                        &sampler.d3d_desc,
                        dest_descriptor,
                    );
                }
            }
        }

        // Resource tracking and dynamic resources
        var dynamic_resources = try allocator.alloc(DynamicResource, layout.dynamic_entries.items.len);
        errdefer allocator.free(dynamic_resources);

        var buffers = std.ArrayListUnmanaged(*Buffer){};
        errdefer buffers.deinit(allocator);

        var textures = std.ArrayListUnmanaged(*Texture){};
        errdefer textures.deinit(allocator);

        var accesses = std.ArrayListUnmanaged(ResourceAccess){};
        errdefer accesses.deinit(allocator);

        for (0..desc.entry_count) |i| {
            const entry = desc.entries.?[i];
            const layout_entry = layout.getEntry(entry.binding) orelse return error.UnknownBinding;

            if (layout_entry.buffer.type != .undefined) {
                const buffer: *Buffer = @ptrCast(@alignCast(entry.buffer.?));
                const d3d_resource = buffer.resource.d3d_resource;

                try buffers.append(allocator, buffer);
                buffer.manager.reference();

                const buffer_location = d3d_resource.lpVtbl.*.GetGPUVirtualAddress.?(d3d_resource) + entry.offset;
                if (layout_entry.dynamic_index) |dynamic_index| {
                    const layout_dynamic_entry = layout.dynamic_entries.items[dynamic_index];
                    dynamic_resources[dynamic_index] = .{
                        .address = buffer_location,
                        .parameter_type = layout_dynamic_entry.parameter_type,
                    };
                }

                try accesses.append(allocator, .{ .resource = &buffer.resource, .uav = layout_entry.buffer.type == .storage });
            } else if (layout_entry.sampler.type != .undefined) {} else if (layout_entry.texture.sample_type != .undefined) {
                const texture_view: *TextureView = @ptrCast(@alignCast(entry.texture_view.?));
                const texture = texture_view.texture;

                try textures.append(allocator, texture);
                texture.manager.reference();

                try accesses.append(allocator, .{ .resource = &texture.resource, .uav = false });
            } else if (layout_entry.storage_texture.format != .undefined) {
                const texture_view: *TextureView = @ptrCast(@alignCast(entry.texture_view.?));
                const texture = texture_view.texture;

                try textures.append(allocator, texture);
                texture.manager.reference();

                try accesses.append(allocator, .{ .resource = &texture.resource, .uav = true });
            }
        }

        const group = try allocator.create(BindGroup);
        group.* = .{
            .device = device,
            .general_allocation = general_allocation,
            .general_table = general_table,
            .sampler_allocation = sampler_allocation,
            .sampler_table = sampler_table,
            .dynamic_resources = dynamic_resources,
            .buffers = buffers,
            .textures = textures,
            .accesses = accesses,
        };
        return group;
    }

    pub fn deinit(group: *BindGroup) void {
        if (group.general_allocation) |allocation|
            group.device.general_heap.free(allocation);
        if (group.sampler_allocation) |allocation|
            group.device.sampler_heap.free(allocation);

        for (group.buffers.items) |buffer| buffer.manager.release();
        for (group.textures.items) |texture| texture.manager.release();

        group.buffers.deinit(allocator);
        group.textures.deinit(allocator);
        group.accesses.deinit(allocator);
        allocator.free(group.dynamic_resources);
        allocator.destroy(group);
    }
};

pub const PipelineLayout = struct {
    pub const Function = struct {
        stage: sysgpu.ShaderStageFlags,
        shader_module: *ShaderModule,
        entry_point: [*:0]const u8,
    };

    manager: utils.Manager(PipelineLayout) = .{},
    root_signature: *c.ID3D12RootSignature,
    group_layouts: []*BindGroupLayout,
    group_parameter_indices: std.BoundedArray(u32, limits.max_bind_groups),

    pub fn init(device: *Device, desc: *const sysgpu.PipelineLayout.Descriptor) !*PipelineLayout {
        const d3d_device = device.d3d_device;
        var hr: c.HRESULT = undefined;

        // Per Bind Group:
        // - up to 1 descriptor table for CBV/SRV/UAV
        // - up to 1 descriptor table for Sampler
        // - 1 root descriptor per dynamic resource
        // Root signature 1.1 hints not supported yet

        var group_layouts = try allocator.alloc(*BindGroupLayout, desc.bind_group_layout_count);
        errdefer allocator.free(group_layouts);

        var group_parameter_indices = std.BoundedArray(u32, limits.max_bind_groups){};

        var parameter_count: u32 = 0;
        var range_count: u32 = 0;
        for (0..desc.bind_group_layout_count) |i| {
            const layout: *BindGroupLayout = @ptrCast(@alignCast(desc.bind_group_layouts.?[i]));
            layout.manager.reference();
            group_layouts[i] = layout;
            group_parameter_indices.appendAssumeCapacity(parameter_count);

            var general_entry_count: u32 = 0;
            var sampler_entry_count: u32 = 0;
            for (layout.entries.items) |entry| {
                if (entry.dynamic_index) |_| {
                    parameter_count += 1;
                } else if (entry.sampler.type != .undefined) {
                    sampler_entry_count += 1;
                    range_count += 1;
                } else {
                    general_entry_count += 1;
                    range_count += 1;
                }
            }

            if (general_entry_count > 0)
                parameter_count += 1;
            if (sampler_entry_count > 0)
                parameter_count += 1;
        }

        var parameters = try std.ArrayListUnmanaged(c.D3D12_ROOT_PARAMETER).initCapacity(allocator, parameter_count);
        defer parameters.deinit(allocator);

        var ranges = try std.ArrayListUnmanaged(c.D3D12_DESCRIPTOR_RANGE).initCapacity(allocator, range_count);
        defer ranges.deinit(allocator);

        for (0..desc.bind_group_layout_count) |group_index| {
            const layout: *BindGroupLayout = group_layouts[group_index];

            // General Table
            {
                const entry_range_base = ranges.items.len;
                for (layout.entries.items) |entry| {
                    if (entry.dynamic_index == null and entry.sampler.type == .undefined) {
                        ranges.appendAssumeCapacity(.{
                            .RangeType = entry.range_type,
                            .NumDescriptors = 1,
                            .BaseShaderRegister = entry.binding,
                            .RegisterSpace = @intCast(group_index),
                            .OffsetInDescriptorsFromTableStart = c.D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND,
                        });
                    }
                }
                const entry_range_count = ranges.items.len - entry_range_base;
                if (entry_range_count > 0) {
                    parameters.appendAssumeCapacity(.{
                        .ParameterType = c.D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE,
                        .unnamed_0 = .{
                            .DescriptorTable = .{
                                .NumDescriptorRanges = @intCast(entry_range_count),
                                .pDescriptorRanges = &ranges.items[entry_range_base],
                            },
                        },
                        .ShaderVisibility = c.D3D12_SHADER_VISIBILITY_ALL,
                    });
                }
            }

            // Sampler Table
            {
                const entry_range_base = ranges.items.len;
                for (layout.entries.items) |entry| {
                    if (entry.dynamic_index == null and entry.sampler.type != .undefined) {
                        ranges.appendAssumeCapacity(.{
                            .RangeType = entry.range_type,
                            .NumDescriptors = 1,
                            .BaseShaderRegister = entry.binding,
                            .RegisterSpace = @intCast(group_index),
                            .OffsetInDescriptorsFromTableStart = c.D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND,
                        });
                    }
                }
                const entry_range_count = ranges.items.len - entry_range_base;
                if (entry_range_count > 0) {
                    parameters.appendAssumeCapacity(.{
                        .ParameterType = c.D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE,
                        .unnamed_0 = .{
                            .DescriptorTable = .{
                                .NumDescriptorRanges = @intCast(entry_range_count),
                                .pDescriptorRanges = &ranges.items[entry_range_base],
                            },
                        },
                        .ShaderVisibility = c.D3D12_SHADER_VISIBILITY_ALL,
                    });
                }
            }

            // Dynamic Resources
            for (layout.entries.items) |entry| {
                if (entry.dynamic_index) |dynamic_index| {
                    const layout_dynamic_entry = layout.dynamic_entries.items[dynamic_index];
                    parameters.appendAssumeCapacity(.{
                        .ParameterType = layout_dynamic_entry.parameter_type,
                        .unnamed_0 = .{
                            .Descriptor = .{
                                .ShaderRegister = entry.binding,
                                .RegisterSpace = @intCast(group_index),
                            },
                        },
                        .ShaderVisibility = c.D3D12_SHADER_VISIBILITY_ALL,
                    });
                }
            }
        }

        var root_signature_blob: *c.ID3DBlob = undefined;
        var opt_errors: ?*c.ID3DBlob = null;
        hr = c.D3D12SerializeRootSignature(
            &c.D3D12_ROOT_SIGNATURE_DESC{
                .NumParameters = @intCast(parameters.items.len),
                .pParameters = parameters.items.ptr,
                .NumStaticSamplers = 0,
                .pStaticSamplers = null,
                .Flags = c.D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT, // TODO - would like a flag for this
            },
            c.D3D_ROOT_SIGNATURE_VERSION_1,
            @ptrCast(&root_signature_blob),
            @ptrCast(&opt_errors),
        );
        if (opt_errors) |errors| {
            const message: [*:0]const u8 = @ptrCast(errors.lpVtbl.*.GetBufferPointer.?(errors).?);
            std.debug.print("{s}\n", .{message});
            _ = errors.lpVtbl.*.Release.?(errors);
        }
        if (hr != c.S_OK) {
            return error.SerializeRootSignatureFailed;
        }
        defer _ = root_signature_blob.lpVtbl.*.Release.?(root_signature_blob);

        var root_signature: *c.ID3D12RootSignature = undefined;
        hr = d3d_device.lpVtbl.*.CreateRootSignature.?(
            d3d_device,
            0,
            root_signature_blob.lpVtbl.*.GetBufferPointer.?(root_signature_blob),
            root_signature_blob.lpVtbl.*.GetBufferSize.?(root_signature_blob),
            &c.IID_ID3D12RootSignature,
            @ptrCast(&root_signature),
        );
        errdefer _ = root_signature.lpVtbl.*.Release.?(root_signature);

        // Result
        const layout = try allocator.create(PipelineLayout);
        layout.* = .{
            .root_signature = root_signature,
            .group_layouts = group_layouts,
            .group_parameter_indices = group_parameter_indices,
        };
        return layout;
    }

    pub fn initDefault(device: *Device, default_pipeline_layout: utils.DefaultPipelineLayoutDescriptor) !*PipelineLayout {
        const groups = default_pipeline_layout.groups;
        var bind_group_layouts = std.BoundedArray(*sysgpu.BindGroupLayout, limits.max_bind_groups){};
        defer {
            for (bind_group_layouts.slice()) |bind_group_layout| bind_group_layout.release();
        }

        for (groups.slice()) |entries| {
            const bind_group_layout = try device.createBindGroupLayout(
                &sysgpu.BindGroupLayout.Descriptor.init(.{ .entries = entries.items }),
            );
            bind_group_layouts.appendAssumeCapacity(@ptrCast(bind_group_layout));
        }

        return device.createPipelineLayout(
            &sysgpu.PipelineLayout.Descriptor.init(.{ .bind_group_layouts = bind_group_layouts.slice() }),
        );
    }

    pub fn deinit(layout: *PipelineLayout) void {
        const root_signature = layout.root_signature;

        for (layout.group_layouts) |group_layout| group_layout.manager.release();

        _ = root_signature.lpVtbl.*.Release.?(root_signature);
        allocator.free(layout.group_layouts);
        allocator.destroy(layout);
    }
};

pub const ShaderModule = struct {
    manager: utils.Manager(ShaderModule) = .{},
    code: union(enum) {
        code: []const u8,
        air: *shader.Air,
    },

    pub fn initAir(device: *Device, air: *shader.Air) !*ShaderModule {
        _ = device;
        const module = try allocator.create(ShaderModule);
        module.* = .{ .code = .{ .air = air } };
        return module;
    }

    pub fn deinit(module: *ShaderModule) void {
        if (module.code == .air) {
            module.code.air.deinit(allocator);
            allocator.destroy(module.code.air);
        }
        allocator.destroy(module);
    }

    // Internal
    fn compile(module: *ShaderModule, entrypoint: [*:0]const u8, target: [*:0]const u8) !*c.ID3DBlob {
        var hr: c.HRESULT = undefined;

        const code = switch (module.code) {
            .air => |air| try shader.CodeGen.generate(allocator, air, .hlsl, false, .{ .emit_source_file = "" }, null, null, null),
            .code => |code| code,
        };
        defer if (module.code == .air) allocator.free(code);

        var flags: u32 = 0;
        if (debug_enabled)
            flags |= c.D3DCOMPILE_DEBUG | c.D3DCOMPILE_SKIP_OPTIMIZATION;

        var shader_blob: *c.ID3DBlob = undefined;
        var opt_errors: ?*c.ID3DBlob = null;
        hr = c.D3DCompile(
            code.ptr,
            code.len,
            null,
            null,
            null,
            entrypoint,
            target,
            flags,
            0,
            @ptrCast(&shader_blob),
            @ptrCast(&opt_errors),
        );
        if (opt_errors) |errors| {
            const message: [*:0]const u8 = @ptrCast(errors.lpVtbl.*.GetBufferPointer.?(errors).?);
            std.debug.print("{s}\n", .{message});
            _ = errors.lpVtbl.*.Release.?(errors);
        }
        if (hr != c.S_OK) {
            return error.CompileShaderFailed;
        }

        return shader_blob;
    }
};

pub const ComputePipeline = struct {
    manager: utils.Manager(ComputePipeline) = .{},
    device: *Device,
    d3d_pipeline: *c.ID3D12PipelineState,
    layout: *PipelineLayout,

    pub fn init(device: *Device, desc: *const sysgpu.ComputePipeline.Descriptor) !*ComputePipeline {
        const d3d_device = device.d3d_device;
        var hr: c.HRESULT = undefined;

        const compute_module: *ShaderModule = @ptrCast(@alignCast(desc.compute.module));

        // Pipeline Layout
        var layout: *PipelineLayout = undefined;
        if (desc.layout) |layout_raw| {
            layout = @ptrCast(@alignCast(layout_raw));
            layout.manager.reference();
        } else if (compute_module.code == .air) {
            var layout_desc = utils.DefaultPipelineLayoutDescriptor.init(allocator);
            defer layout_desc.deinit();

            try layout_desc.addFunction(compute_module.code.air, .{ .compute = true }, desc.compute.entry_point);
            layout = try PipelineLayout.initDefault(device, layout_desc);
        } else {
            @panic(
                \\Cannot create pipeline descriptor autoamtically.
                \\Please provide it yourself or write the shader in WGSL.
            );
        }
        errdefer layout.manager.release();

        // Shaders
        const compute_shader = try compute_module.compile(desc.compute.entry_point, "cs_5_1");
        defer _ = compute_shader.lpVtbl.*.Release.?(compute_shader);

        // PSO
        var d3d_pipeline: *c.ID3D12PipelineState = undefined;
        hr = d3d_device.lpVtbl.*.CreateComputePipelineState.?(
            d3d_device,
            &c.D3D12_COMPUTE_PIPELINE_STATE_DESC{
                .pRootSignature = layout.root_signature,
                .CS = conv.d3d12ShaderBytecode(compute_shader),
                .NodeMask = 0,
                .CachedPSO = .{ .pCachedBlob = null, .CachedBlobSizeInBytes = 0 },
                .Flags = c.D3D12_PIPELINE_STATE_FLAG_NONE,
            },
            &c.IID_ID3D12PipelineState,
            @ptrCast(&d3d_pipeline),
        );
        if (hr != c.S_OK) {
            return error.CreateComputePipelineFailed;
        }
        errdefer _ = d3d_pipeline.lpVtbl.*.Release.?(d3d_pipeline);

        if (desc.label) |label|
            setDebugName(@ptrCast(d3d_pipeline), label);

        // Result
        const pipeline = try allocator.create(ComputePipeline);
        pipeline.* = .{
            .device = device,
            .d3d_pipeline = d3d_pipeline,
            .layout = layout,
        };
        return pipeline;
    }

    pub fn deinit(pipeline: *ComputePipeline) void {
        const d3d_pipeline = pipeline.d3d_pipeline;

        pipeline.layout.manager.release();
        _ = d3d_pipeline.lpVtbl.*.Release.?(d3d_pipeline);
        allocator.destroy(pipeline);
    }

    pub fn getBindGroupLayout(pipeline: *ComputePipeline, group_index: u32) *BindGroupLayout {
        return @ptrCast(pipeline.layout.group_layouts[group_index]);
    }
};

pub const RenderPipeline = struct {
    manager: utils.Manager(RenderPipeline) = .{},
    device: *Device,
    d3d_pipeline: *c.ID3D12PipelineState,
    layout: *PipelineLayout,
    topology: c.D3D12_PRIMITIVE_TOPOLOGY_TYPE,
    vertex_strides: std.BoundedArray(c.UINT, limits.max_vertex_buffers),

    pub fn init(device: *Device, desc: *const sysgpu.RenderPipeline.Descriptor) !*RenderPipeline {
        const d3d_device = device.d3d_device;
        var hr: c.HRESULT = undefined;

        const vertex_module: *ShaderModule = @ptrCast(@alignCast(desc.vertex.module));

        // Pipeline Layout
        var layout: *PipelineLayout = undefined;
        if (desc.layout) |layout_raw| {
            layout = @ptrCast(@alignCast(layout_raw));
            layout.manager.reference();
        } else if (vertex_module.code == .air) {
            var layout_desc = utils.DefaultPipelineLayoutDescriptor.init(allocator);
            defer layout_desc.deinit();

            try layout_desc.addFunction(vertex_module.code.air, .{ .vertex = true }, desc.vertex.entry_point);
            if (desc.fragment) |frag| {
                const frag_module: *ShaderModule = @ptrCast(@alignCast(frag.module));
                if (frag_module.code == .air) {
                    try layout_desc.addFunction(frag_module.code.air, .{ .fragment = true }, frag.entry_point);
                } else {
                    @panic(
                        \\Cannot create pipeline descriptor autoamtically.
                        \\Please provide it yourself or write the shader in WGSL.
                    );
                }
            }
            layout = try PipelineLayout.initDefault(device, layout_desc);
        } else {
            @panic(
                \\Cannot create pipeline descriptor autoamtically.
                \\Please provide it yourself or write the shader in WGSL.
            );
        }
        errdefer layout.manager.release();

        // Shaders
        const vertex_shader = try vertex_module.compile(desc.vertex.entry_point, "vs_5_1");
        defer _ = vertex_shader.lpVtbl.*.Release.?(vertex_shader);

        var opt_pixel_shader: ?*c.ID3DBlob = null;
        if (desc.fragment) |frag| {
            const frag_module: *ShaderModule = @ptrCast(@alignCast(frag.module));
            opt_pixel_shader = try frag_module.compile(frag.entry_point, "ps_5_1");
        }
        defer if (opt_pixel_shader) |pixel_shader| {
            _ = pixel_shader.lpVtbl.*.Release.?(pixel_shader);
        };

        // PSO
        var input_elements = std.BoundedArray(c.D3D12_INPUT_ELEMENT_DESC, limits.max_vertex_buffers){};
        var vertex_strides = std.BoundedArray(c.UINT, limits.max_vertex_buffers){};
        for (0..desc.vertex.buffer_count) |i| {
            const buffer = desc.vertex.buffers.?[i];
            for (0..buffer.attribute_count) |j| {
                const attr = buffer.attributes.?[j];
                input_elements.appendAssumeCapacity(conv.d3d12InputElementDesc(i, buffer, attr));
            }
            vertex_strides.appendAssumeCapacity(@intCast(buffer.array_stride));
        }

        var num_render_targets: usize = 0;
        var rtv_formats = [_]c.DXGI_FORMAT{c.DXGI_FORMAT_UNKNOWN} ** limits.max_color_attachments;
        if (desc.fragment) |frag| {
            num_render_targets = frag.target_count;
            for (0..frag.target_count) |i| {
                const target = frag.targets.?[i];
                rtv_formats[i] = conv.dxgiFormatForTexture(target.format);
            }
        }

        var d3d_pipeline: *c.ID3D12PipelineState = undefined;
        hr = d3d_device.lpVtbl.*.CreateGraphicsPipelineState.?(
            d3d_device,
            &c.D3D12_GRAPHICS_PIPELINE_STATE_DESC{
                .pRootSignature = layout.root_signature,
                .VS = conv.d3d12ShaderBytecode(vertex_shader),
                .PS = conv.d3d12ShaderBytecode(opt_pixel_shader),
                .DS = conv.d3d12ShaderBytecode(null),
                .HS = conv.d3d12ShaderBytecode(null),
                .GS = conv.d3d12ShaderBytecode(null),
                .StreamOutput = conv.d3d12StreamOutputDesc(),
                .BlendState = conv.d3d12BlendDesc(desc),
                .SampleMask = desc.multisample.mask,
                .RasterizerState = conv.d3d12RasterizerDesc(desc),
                .DepthStencilState = conv.d3d12DepthStencilDesc(desc.depth_stencil),
                .InputLayout = .{
                    .pInputElementDescs = if (desc.vertex.buffer_count > 0) &input_elements.buffer else null,
                    .NumElements = @intCast(input_elements.len),
                },
                .IBStripCutValue = conv.d3d12IndexBufferStripCutValue(desc.primitive.strip_index_format),
                .PrimitiveTopologyType = conv.d3d12PrimitiveTopologyType(desc.primitive.topology),
                .NumRenderTargets = @intCast(num_render_targets),
                .RTVFormats = rtv_formats,
                .DSVFormat = if (desc.depth_stencil) |ds| conv.dxgiFormatForTexture(ds.format) else c.DXGI_FORMAT_UNKNOWN,
                .SampleDesc = .{ .Count = desc.multisample.count, .Quality = 0 },
                .NodeMask = 0,
                .CachedPSO = .{ .pCachedBlob = null, .CachedBlobSizeInBytes = 0 },
                .Flags = c.D3D12_PIPELINE_STATE_FLAG_NONE,
            },
            &c.IID_ID3D12PipelineState,
            @ptrCast(&d3d_pipeline),
        );
        if (hr != c.S_OK) {
            return error.CreateRenderPipelineFailed;
        }
        errdefer _ = d3d_pipeline.lpVtbl.*.Release.?(d3d_pipeline);

        if (desc.label) |label|
            setDebugName(@ptrCast(d3d_pipeline), label);

        // Result
        const pipeline = try allocator.create(RenderPipeline);
        pipeline.* = .{
            .d3d_pipeline = d3d_pipeline,
            .device = device,
            .layout = layout,
            .topology = conv.d3d12PrimitiveTopology(desc.primitive.topology),
            .vertex_strides = vertex_strides,
        };
        return pipeline;
    }

    pub fn deinit(pipeline: *RenderPipeline) void {
        const d3d_pipeline = pipeline.d3d_pipeline;

        pipeline.layout.manager.release();
        _ = d3d_pipeline.lpVtbl.*.Release.?(d3d_pipeline);
        allocator.destroy(pipeline);
    }

    pub fn getBindGroupLayout(pipeline: *RenderPipeline, group_index: u32) *BindGroupLayout {
        return @ptrCast(pipeline.layout.group_layouts[group_index]);
    }
};

pub const CommandBuffer = struct {
    pub const StreamingResult = struct {
        d3d_resource: *c.ID3D12Resource,
        map: [*]u8,
        offset: u32,
    };

    manager: utils.Manager(CommandBuffer) = .{},
    device: *Device,
    command_allocator: *c.ID3D12CommandAllocator,
    command_list: *c.ID3D12GraphicsCommandList,
    reference_tracker: *ReferenceTracker,
    rtv_allocation: DescriptorAllocation = .{ .index = 0 },
    rtv_next_index: u32 = rtv_block_size,
    upload_buffer: ?*c.ID3D12Resource = null,
    upload_map: ?[*]u8 = null,
    upload_next_offset: u32 = upload_page_size,

    pub fn init(device: *Device) !*CommandBuffer {
        const command_allocator = try device.command_manager.createCommandAllocator();
        errdefer device.command_manager.destroyCommandAllocator(command_allocator);

        const command_list = try device.command_manager.createCommandList(command_allocator);
        errdefer device.command_manager.destroyCommandList(command_list);

        const heaps = [2]*c.ID3D12DescriptorHeap{ device.general_heap.d3d_heap, device.sampler_heap.d3d_heap };
        command_list.lpVtbl.*.SetDescriptorHeaps.?(
            command_list,
            2,
            &heaps,
        );

        const reference_tracker = try ReferenceTracker.init(device, command_allocator);
        errdefer reference_tracker.deinit();

        const command_buffer = try allocator.create(CommandBuffer);
        command_buffer.* = .{
            .device = device,
            .command_allocator = command_allocator,
            .command_list = command_list,
            .reference_tracker = reference_tracker,
        };
        return command_buffer;
    }

    pub fn deinit(command_buffer: *CommandBuffer) void {
        // reference_tracker lifetime is managed externally
        // command_allocator lifetime is managed externally
        // command_list lifetime is managed externally
        allocator.destroy(command_buffer);
    }

    // Internal
    pub fn upload(command_buffer: *CommandBuffer, size: u64) !StreamingResult {
        if (command_buffer.upload_next_offset + size > upload_page_size) {
            const streaming_manager = &command_buffer.device.streaming_manager;
            var hr: c.HRESULT = undefined;

            std.debug.assert(size <= upload_page_size); // TODO - support large uploads
            const resource = try streaming_manager.acquire();
            const d3d_resource = resource.d3d_resource;

            try command_buffer.reference_tracker.referenceUploadPage(resource);
            command_buffer.upload_buffer = d3d_resource;

            var map: ?*anyopaque = null;
            hr = d3d_resource.lpVtbl.*.Map.?(d3d_resource, 0, null, &map);
            if (hr != c.S_OK) {
                return error.MapForUploadFailed;
            }

            command_buffer.upload_map = @ptrCast(map);
            command_buffer.upload_next_offset = 0;
        }

        const offset = command_buffer.upload_next_offset;
        command_buffer.upload_next_offset = @intCast(utils.alignUp(offset + size, limits.min_uniform_buffer_offset_alignment));
        return StreamingResult{
            .d3d_resource = command_buffer.upload_buffer.?,
            .map = command_buffer.upload_map.? + offset,
            .offset = offset,
        };
    }

    pub fn allocateRtvDescriptors(command_buffer: *CommandBuffer, count: usize) !c.D3D12_CPU_DESCRIPTOR_HANDLE {
        if (count == 0) return .{ .ptr = 0 };

        var rtv_heap = &command_buffer.device.rtv_heap;

        if (command_buffer.rtv_next_index + count > rtv_block_size) {
            command_buffer.rtv_allocation = try rtv_heap.alloc();

            try command_buffer.reference_tracker.referenceRtvDescriptorBlock(command_buffer.rtv_allocation);
            command_buffer.rtv_next_index = 0;
        }

        const index = command_buffer.rtv_next_index;
        command_buffer.rtv_next_index = @intCast(index + count);
        return rtv_heap.cpuDescriptor(command_buffer.rtv_allocation.index + index);
    }

    pub fn allocateDsvDescriptor(command_buffer: *CommandBuffer) !c.D3D12_CPU_DESCRIPTOR_HANDLE {
        var dsv_heap = &command_buffer.device.dsv_heap;

        const allocation = try dsv_heap.alloc();
        try command_buffer.reference_tracker.referenceDsvDescriptorBlock(allocation);

        return dsv_heap.cpuDescriptor(allocation.index);
    }
};

pub const ReferenceTracker = struct {
    device: *Device,
    command_allocator: *c.ID3D12CommandAllocator,
    fence_value: u64 = 0,
    buffers: std.ArrayListUnmanaged(*Buffer) = .{},
    textures: std.ArrayListUnmanaged(*Texture) = .{},
    bind_groups: std.ArrayListUnmanaged(*BindGroup) = .{},
    compute_pipelines: std.ArrayListUnmanaged(*ComputePipeline) = .{},
    render_pipelines: std.ArrayListUnmanaged(*RenderPipeline) = .{},
    rtv_descriptor_blocks: std.ArrayListUnmanaged(DescriptorAllocation) = .{},
    dsv_descriptor_blocks: std.ArrayListUnmanaged(DescriptorAllocation) = .{},
    upload_pages: std.ArrayListUnmanaged(Resource) = .{},

    pub fn init(device: *Device, command_allocator: *c.ID3D12CommandAllocator) !*ReferenceTracker {
        const tracker = try allocator.create(ReferenceTracker);
        tracker.* = .{
            .device = device,
            .command_allocator = command_allocator,
        };
        return tracker;
    }

    pub fn deinit(tracker: *ReferenceTracker) void {
        const device = tracker.device;

        device.command_manager.destroyCommandAllocator(tracker.command_allocator);

        for (tracker.buffers.items) |buffer| {
            buffer.gpu_count -= 1;
            buffer.manager.release();
        }

        for (tracker.textures.items) |texture| {
            texture.manager.release();
        }

        for (tracker.bind_groups.items) |group| {
            for (group.buffers.items) |buffer| buffer.gpu_count -= 1;
            group.manager.release();
        }

        for (tracker.compute_pipelines.items) |pipeline| {
            pipeline.manager.release();
        }

        for (tracker.render_pipelines.items) |pipeline| {
            pipeline.manager.release();
        }

        for (tracker.rtv_descriptor_blocks.items) |block| {
            device.rtv_heap.free(block);
        }

        for (tracker.dsv_descriptor_blocks.items) |block| {
            device.dsv_heap.free(block);
        }

        for (tracker.upload_pages.items) |resource| {
            device.streaming_manager.release(resource);
        }

        tracker.buffers.deinit(allocator);
        tracker.textures.deinit(allocator);
        tracker.bind_groups.deinit(allocator);
        tracker.compute_pipelines.deinit(allocator);
        tracker.render_pipelines.deinit(allocator);
        tracker.rtv_descriptor_blocks.deinit(allocator);
        tracker.dsv_descriptor_blocks.deinit(allocator);
        tracker.upload_pages.deinit(allocator);
        allocator.destroy(tracker);
    }

    pub fn referenceBuffer(tracker: *ReferenceTracker, buffer: *Buffer) !void {
        buffer.manager.reference();
        try tracker.buffers.append(allocator, buffer);
    }

    pub fn referenceTexture(tracker: *ReferenceTracker, texture: *Texture) !void {
        texture.manager.reference();
        try tracker.textures.append(allocator, texture);
    }

    pub fn referenceBindGroup(tracker: *ReferenceTracker, group: *BindGroup) !void {
        group.manager.reference();
        try tracker.bind_groups.append(allocator, group);
    }

    pub fn referenceComputePipeline(tracker: *ReferenceTracker, pipeline: *ComputePipeline) !void {
        pipeline.manager.reference();
        try tracker.compute_pipelines.append(allocator, pipeline);
    }

    pub fn referenceRenderPipeline(tracker: *ReferenceTracker, pipeline: *RenderPipeline) !void {
        pipeline.manager.reference();
        try tracker.render_pipelines.append(allocator, pipeline);
    }

    pub fn referenceRtvDescriptorBlock(tracker: *ReferenceTracker, block: DescriptorAllocation) !void {
        try tracker.rtv_descriptor_blocks.append(allocator, block);
    }

    pub fn referenceDsvDescriptorBlock(tracker: *ReferenceTracker, block: DescriptorAllocation) !void {
        try tracker.dsv_descriptor_blocks.append(allocator, block);
    }

    pub fn referenceUploadPage(tracker: *ReferenceTracker, upload_page: Resource) !void {
        try tracker.upload_pages.append(allocator, upload_page);
    }

    pub fn submit(tracker: *ReferenceTracker, queue: *Queue) !void {
        tracker.fence_value = queue.fence_value;

        for (tracker.buffers.items) |buffer| {
            buffer.gpu_count += 1;
        }

        for (tracker.bind_groups.items) |group| {
            for (group.buffers.items) |buffer| buffer.gpu_count += 1;
        }

        try tracker.device.reference_trackers.append(allocator, tracker);
    }
};

pub const CommandEncoder = struct {
    manager: utils.Manager(CommandEncoder) = .{},
    device: *Device,
    command_buffer: *CommandBuffer,
    reference_tracker: *ReferenceTracker,
    state_tracker: StateTracker = .{},

    pub fn init(device: *Device, desc: ?*const sysgpu.CommandEncoder.Descriptor) !*CommandEncoder {
        // TODO
        _ = desc;

        const command_buffer = try CommandBuffer.init(device);

        var encoder = try allocator.create(CommandEncoder);
        encoder.* = .{
            .device = device,
            .command_buffer = command_buffer,
            .reference_tracker = command_buffer.reference_tracker,
        };
        encoder.state_tracker.init(device);
        return encoder;
    }

    pub fn deinit(encoder: *CommandEncoder) void {
        encoder.state_tracker.deinit();
        encoder.command_buffer.manager.release();
        allocator.destroy(encoder);
    }

    pub fn beginComputePass(encoder: *CommandEncoder, desc: *const sysgpu.ComputePassDescriptor) !*ComputePassEncoder {
        return ComputePassEncoder.init(encoder, desc);
    }

    pub fn beginRenderPass(encoder: *CommandEncoder, desc: *const sysgpu.RenderPassDescriptor) !*RenderPassEncoder {
        try encoder.state_tracker.endPass();
        return RenderPassEncoder.init(encoder, desc);
    }

    pub fn copyBufferToBuffer(
        encoder: *CommandEncoder,
        source: *Buffer,
        source_offset: u64,
        destination: *Buffer,
        destination_offset: u64,
        size: u64,
    ) !void {
        const command_list = encoder.command_buffer.command_list;

        try encoder.reference_tracker.referenceBuffer(source);
        try encoder.reference_tracker.referenceBuffer(destination);
        try encoder.state_tracker.transition(&source.resource, source.resource.read_state);
        try encoder.state_tracker.transition(&destination.resource, c.D3D12_RESOURCE_STATE_COPY_DEST);
        encoder.state_tracker.flush(command_list);

        command_list.lpVtbl.*.CopyBufferRegion.?(
            command_list,
            destination.resource.d3d_resource,
            destination_offset,
            source.resource.d3d_resource,
            source_offset,
            size,
        );
    }

    pub fn copyBufferToTexture(
        encoder: *CommandEncoder,
        source: *const sysgpu.ImageCopyBuffer,
        destination: *const sysgpu.ImageCopyTexture,
        copy_size_raw: *const sysgpu.Extent3D,
    ) !void {
        const command_list = encoder.command_buffer.command_list;
        const source_buffer: *Buffer = @ptrCast(@alignCast(source.buffer));
        const destination_texture: *Texture = @ptrCast(@alignCast(destination.texture));

        try encoder.reference_tracker.referenceBuffer(source_buffer);
        try encoder.reference_tracker.referenceTexture(destination_texture);
        try encoder.state_tracker.transition(&source_buffer.resource, source_buffer.resource.read_state);
        try encoder.state_tracker.transition(&destination_texture.resource, c.D3D12_RESOURCE_STATE_COPY_DEST);
        encoder.state_tracker.flush(command_list);

        const copy_size = utils.calcExtent(destination_texture.dimension, copy_size_raw.*);
        const destination_origin = utils.calcOrigin(destination_texture.dimension, destination.origin);
        const destination_subresource_index = destination_texture.calcSubresource(destination.mip_level, destination_origin.array_slice);

        std.debug.assert(copy_size.array_count == 1); // TODO

        command_list.lpVtbl.*.CopyTextureRegion.?(
            command_list,
            &.{
                .pResource = destination_texture.resource.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX,
                .unnamed_0 = .{
                    .SubresourceIndex = destination_subresource_index,
                },
            },
            destination_origin.x,
            destination_origin.y,
            destination_origin.z,
            &.{
                .pResource = source_buffer.resource.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT,
                .unnamed_0 = .{
                    .PlacedFootprint = .{
                        .Offset = source.layout.offset,
                        .Footprint = .{
                            .Format = conv.dxgiFormatForTexture(destination_texture.format),
                            .Width = copy_size.width,
                            .Height = copy_size.height,
                            .Depth = copy_size.depth,
                            .RowPitch = source.layout.bytes_per_row,
                        },
                    },
                },
            },
            null,
        );
    }

    pub fn copyTextureToTexture(
        encoder: *CommandEncoder,
        source: *const sysgpu.ImageCopyTexture,
        destination: *const sysgpu.ImageCopyTexture,
        copy_size_raw: *const sysgpu.Extent3D,
    ) !void {
        const command_list = encoder.command_buffer.command_list;
        const source_texture: *Texture = @ptrCast(@alignCast(source.texture));
        const destination_texture: *Texture = @ptrCast(@alignCast(destination.texture));

        try encoder.reference_tracker.referenceTexture(source_texture);
        try encoder.reference_tracker.referenceTexture(destination_texture);
        try encoder.state_tracker.transition(&source_texture.resource, source_texture.resource.read_state);
        try encoder.state_tracker.transition(&destination_texture.resource, c.D3D12_RESOURCE_STATE_COPY_DEST);
        encoder.state_tracker.flush(command_list);

        const copy_size = utils.calcExtent(destination_texture.dimension, copy_size_raw.*);
        const source_origin = utils.calcOrigin(source_texture.dimension, source.origin);
        const destination_origin = utils.calcOrigin(destination_texture.dimension, destination.origin);

        const source_subresource_index = source_texture.calcSubresource(source.mip_level, source_origin.array_slice);
        const destination_subresource_index = destination_texture.calcSubresource(destination.mip_level, destination_origin.array_slice);

        std.debug.assert(copy_size.array_count == 1); // TODO

        command_list.lpVtbl.*.CopyTextureRegion.?(
            command_list,
            &.{
                .pResource = destination_texture.resource.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX,
                .unnamed_0 = .{
                    .SubresourceIndex = destination_subresource_index,
                },
            },
            destination_origin.x,
            destination_origin.y,
            destination_origin.z,
            &.{
                .pResource = source_texture.resource.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX,
                .unnamed_0 = .{
                    .SubresourceIndex = source_subresource_index,
                },
            },
            &.{
                .left = source_origin.x,
                .top = source_origin.y,
                .front = source_origin.z,
                .right = source_origin.x + copy_size.width,
                .bottom = source_origin.y + copy_size.height,
                .back = source_origin.z + copy_size.depth,
            },
        );
    }

    pub fn finish(encoder: *CommandEncoder, desc: *const sysgpu.CommandBuffer.Descriptor) !*CommandBuffer {
        const command_list = encoder.command_buffer.command_list;
        var hr: c.HRESULT = undefined;

        try encoder.state_tracker.endPass();
        encoder.state_tracker.flush(command_list);

        hr = command_list.lpVtbl.*.Close.?(command_list);
        if (hr != c.S_OK) {
            return error.CommandListCloseFailed;
        }

        if (desc.label) |label|
            setDebugName(@ptrCast(command_list), label);

        return encoder.command_buffer;
    }

    pub fn writeBuffer(encoder: *CommandEncoder, buffer: *Buffer, offset: u64, data: [*]const u8, size: u64) !void {
        const command_list = encoder.command_buffer.command_list;

        const stream = try encoder.command_buffer.upload(size);
        @memcpy(stream.map[0..size], data[0..size]);

        try encoder.reference_tracker.referenceBuffer(buffer);
        try encoder.state_tracker.transition(&buffer.resource, c.D3D12_RESOURCE_STATE_COPY_DEST);
        encoder.state_tracker.flush(command_list);

        command_list.lpVtbl.*.CopyBufferRegion.?(
            command_list,
            buffer.resource.d3d_resource,
            offset,
            stream.d3d_resource,
            stream.offset,
            size,
        );
    }

    pub fn writeTexture(
        encoder: *CommandEncoder,
        destination: *const sysgpu.ImageCopyTexture,
        data: [*]const u8,
        data_size: usize,
        data_layout: *const sysgpu.Texture.DataLayout,
        write_size_raw: *const sysgpu.Extent3D,
    ) !void {
        const command_list = encoder.command_buffer.command_list;
        const destination_texture: *Texture = @ptrCast(@alignCast(destination.texture));

        const stream = try encoder.command_buffer.upload(data_size);
        @memcpy(stream.map[0..data_size], data[0..data_size]);

        try encoder.reference_tracker.referenceTexture(destination_texture);
        try encoder.state_tracker.transition(&destination_texture.resource, c.D3D12_RESOURCE_STATE_COPY_DEST);
        encoder.state_tracker.flush(command_list);

        const write_size = utils.calcExtent(destination_texture.dimension, write_size_raw.*);
        const destination_origin = utils.calcOrigin(destination_texture.dimension, destination.origin);
        const destination_subresource_index = destination_texture.calcSubresource(destination.mip_level, destination_origin.array_slice);

        std.debug.assert(write_size.array_count == 1); // TODO

        command_list.lpVtbl.*.CopyTextureRegion.?(
            command_list,
            &.{
                .pResource = destination_texture.resource.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX,
                .unnamed_0 = .{
                    .SubresourceIndex = destination_subresource_index,
                },
            },
            destination_origin.x,
            destination_origin.y,
            destination_origin.z,
            &.{
                .pResource = stream.d3d_resource,
                .Type = c.D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT,
                .unnamed_0 = .{
                    .PlacedFootprint = .{
                        .Offset = stream.offset,
                        .Footprint = .{
                            .Format = conv.dxgiFormatForTexture(destination_texture.format),
                            .Width = write_size.width,
                            .Height = write_size.height,
                            .Depth = write_size.depth,
                            .RowPitch = data_layout.bytes_per_row,
                        },
                    },
                },
            },
            null,
        );
    }
};

pub const StateTracker = struct {
    device: *Device = undefined,
    written_set: std.AutoArrayHashMapUnmanaged(*Resource, c.D3D12_RESOURCE_STATES) = .{},
    barriers: std.ArrayListUnmanaged(c.D3D12_RESOURCE_BARRIER) = .{},

    pub fn init(tracker: *StateTracker, device: *Device) void {
        tracker.device = device;
    }

    pub fn deinit(tracker: *StateTracker) void {
        tracker.written_set.deinit(allocator);
        tracker.barriers.deinit(allocator);
    }

    pub fn transition(tracker: *StateTracker, resource: *Resource, new_state: c.D3D12_RESOURCE_STATES) !void {
        const current_state = tracker.written_set.get(resource) orelse resource.read_state;

        if (current_state == c.D3D12_RESOURCE_STATE_UNORDERED_ACCESS and
            new_state == c.D3D12_RESOURCE_STATE_UNORDERED_ACCESS)
        {
            try tracker.addUavBarrier(resource);
        } else if (current_state != new_state) {
            try tracker.written_set.put(allocator, resource, new_state);
            try tracker.addTransitionBarrier(resource, current_state, new_state);
        }
    }

    pub fn flush(tracker: *StateTracker, command_list: *c.ID3D12GraphicsCommandList) void {
        if (tracker.barriers.items.len > 0) {
            command_list.lpVtbl.*.ResourceBarrier.?(
                command_list,
                @intCast(tracker.barriers.items.len),
                tracker.barriers.items.ptr,
            );

            tracker.barriers.clearRetainingCapacity();
        }
    }

    pub fn endPass(tracker: *StateTracker) !void {
        var it = tracker.written_set.iterator();
        while (it.next()) |entry| {
            const resource = entry.key_ptr.*;
            const current_state = entry.value_ptr.*;

            if (current_state != resource.read_state)
                try tracker.addTransitionBarrier(resource, current_state, resource.read_state);
        }

        tracker.written_set.clearRetainingCapacity();
    }

    fn addUavBarrier(tracker: *StateTracker, resource: *Resource) !void {
        try tracker.barriers.append(allocator, .{
            .Type = c.D3D12_RESOURCE_BARRIER_TYPE_UAV,
            .Flags = c.D3D12_RESOURCE_BARRIER_FLAG_NONE,
            .unnamed_0 = .{
                .UAV = .{
                    .pResource = resource.d3d_resource,
                },
            },
        });
    }

    fn addTransitionBarrier(
        tracker: *StateTracker,
        resource: *Resource,
        state_before: c.D3D12_RESOURCE_STATES,
        state_after: c.D3D12_RESOURCE_STATES,
    ) !void {
        try tracker.barriers.append(allocator, .{
            .Type = c.D3D12_RESOURCE_BARRIER_TYPE_TRANSITION,
            .Flags = c.D3D12_RESOURCE_BARRIER_FLAG_NONE,
            .unnamed_0 = .{
                .Transition = .{
                    .pResource = resource.d3d_resource,
                    .Subresource = c.D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
                    .StateBefore = state_before,
                    .StateAfter = state_after,
                },
            },
        });
    }
};

pub const ComputePassEncoder = struct {
    manager: utils.Manager(ComputePassEncoder) = .{},
    command_list: *c.ID3D12GraphicsCommandList,
    reference_tracker: *ReferenceTracker,
    state_tracker: *StateTracker,
    bind_groups: [limits.max_bind_groups]*BindGroup = undefined,
    group_parameter_indices: []u32 = undefined,

    pub fn init(cmd_encoder: *CommandEncoder, desc: *const sysgpu.ComputePassDescriptor) !*ComputePassEncoder {
        _ = desc;
        const command_list = cmd_encoder.command_buffer.command_list;

        const encoder = try allocator.create(ComputePassEncoder);
        encoder.* = .{
            .command_list = command_list,
            .reference_tracker = cmd_encoder.reference_tracker,
            .state_tracker = &cmd_encoder.state_tracker,
        };
        return encoder;
    }

    pub fn deinit(encoder: *ComputePassEncoder) void {
        allocator.destroy(encoder);
    }

    pub fn dispatchWorkgroups(
        encoder: *ComputePassEncoder,
        workgroup_count_x: u32,
        workgroup_count_y: u32,
        workgroup_count_z: u32,
    ) !void {
        const command_list = encoder.command_list;

        const bind_group_count = encoder.group_parameter_indices.len;
        for (encoder.bind_groups[0..bind_group_count]) |group| {
            for (group.accesses.items) |access| {
                if (access.uav) {
                    try encoder.state_tracker.transition(access.resource, c.D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
                } else {
                    try encoder.state_tracker.transition(access.resource, access.resource.read_state);
                }
            }
        }
        encoder.state_tracker.flush(command_list);

        command_list.lpVtbl.*.Dispatch.?(
            command_list,
            workgroup_count_x,
            workgroup_count_y,
            workgroup_count_z,
        );
    }

    pub fn end(encoder: *ComputePassEncoder) void {
        _ = encoder;
    }

    pub fn setBindGroup(
        encoder: *ComputePassEncoder,
        group_index: u32,
        group: *BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) !void {
        const command_list = encoder.command_list;

        try encoder.reference_tracker.referenceBindGroup(group);
        encoder.bind_groups[group_index] = group;

        var parameter_index = encoder.group_parameter_indices[group_index];
        if (group.general_table) |table| {
            command_list.lpVtbl.*.SetComputeRootDescriptorTable.?(
                command_list,
                parameter_index,
                table,
            );
            parameter_index += 1;
        }

        if (group.sampler_table) |table| {
            command_list.lpVtbl.*.SetComputeRootDescriptorTable.?(
                command_list,
                parameter_index,
                table,
            );
            parameter_index += 1;
        }

        for (0..dynamic_offset_count) |i| {
            const dynamic_resource = group.dynamic_resources[i];
            const dynamic_offset = dynamic_offsets.?[i];

            switch (dynamic_resource.parameter_type) {
                c.D3D12_ROOT_PARAMETER_TYPE_CBV => command_list.lpVtbl.*.SetComputeRootConstantBufferView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                c.D3D12_ROOT_PARAMETER_TYPE_SRV => command_list.lpVtbl.*.SetComputeRootShaderResourceView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                c.D3D12_ROOT_PARAMETER_TYPE_UAV => command_list.lpVtbl.*.SetComputeRootUnorderedAccessView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                else => {},
            }

            parameter_index += 1;
        }
    }

    pub fn setPipeline(encoder: *ComputePassEncoder, pipeline: *ComputePipeline) !void {
        const command_list = encoder.command_list;

        try encoder.reference_tracker.referenceComputePipeline(pipeline);

        encoder.group_parameter_indices = pipeline.layout.group_parameter_indices.slice();

        command_list.lpVtbl.*.SetComputeRootSignature.?(
            command_list,
            pipeline.layout.root_signature,
        );

        command_list.lpVtbl.*.SetPipelineState.?(
            command_list,
            pipeline.d3d_pipeline,
        );
    }
};

pub const RenderPassEncoder = struct {
    manager: utils.Manager(RenderPassEncoder) = .{},
    command_list: *c.ID3D12GraphicsCommandList,
    reference_tracker: *ReferenceTracker,
    state_tracker: *StateTracker,
    color_attachments: std.BoundedArray(sysgpu.RenderPassColorAttachment, limits.max_color_attachments) = .{},
    depth_attachment: ?sysgpu.RenderPassDepthStencilAttachment,
    group_parameter_indices: []u32 = undefined,
    vertex_apply_count: u32 = 0,
    vertex_buffer_views: [limits.max_vertex_buffers]c.D3D12_VERTEX_BUFFER_VIEW,
    vertex_strides: []c.UINT = undefined,

    pub fn init(cmd_encoder: *CommandEncoder, desc: *const sysgpu.RenderPassDescriptor) !*RenderPassEncoder {
        const d3d_device = cmd_encoder.device.d3d_device;
        const command_list = cmd_encoder.command_buffer.command_list;

        var width: u32 = 0;
        var height: u32 = 0;
        var color_attachments: std.BoundedArray(sysgpu.RenderPassColorAttachment, limits.max_color_attachments) = .{};
        var rtv_handles = try cmd_encoder.command_buffer.allocateRtvDescriptors(desc.color_attachment_count);
        const descriptor_size = cmd_encoder.device.rtv_heap.descriptor_size;

        var rtv_handle = rtv_handles;
        for (0..desc.color_attachment_count) |i| {
            const attach = desc.color_attachments.?[i];
            if (attach.view) |view_raw| {
                const view: *TextureView = @ptrCast(@alignCast(view_raw));
                const texture = view.texture;

                try cmd_encoder.reference_tracker.referenceTexture(texture);
                try cmd_encoder.state_tracker.transition(&texture.resource, c.D3D12_RESOURCE_STATE_RENDER_TARGET);

                width = view.width();
                height = view.height();
                color_attachments.appendAssumeCapacity(attach);

                // TODO - rtvDesc()
                d3d_device.lpVtbl.*.CreateRenderTargetView.?(
                    d3d_device,
                    texture.resource.d3d_resource,
                    null,
                    rtv_handle,
                );
            } else {
                d3d_device.lpVtbl.*.CreateRenderTargetView.?(
                    d3d_device,
                    null,
                    &.{
                        .Format = c.DXGI_FORMAT_R8G8B8A8_UNORM,
                        .ViewDimension = c.D3D12_RTV_DIMENSION_TEXTURE2D,
                        .unnamed_0 = .{ .Texture2D = .{ .MipSlice = 0, .PlaneSlice = 0 } },
                    },
                    rtv_handle,
                );
            }
            rtv_handle.ptr += descriptor_size;
        }

        var depth_attachment: ?sysgpu.RenderPassDepthStencilAttachment = null;
        var dsv_handle: c.D3D12_CPU_DESCRIPTOR_HANDLE = .{ .ptr = 0 };

        if (desc.depth_stencil_attachment) |attach| {
            const view: *TextureView = @ptrCast(@alignCast(attach.view));
            const texture = view.texture;

            try cmd_encoder.reference_tracker.referenceTexture(texture);
            try cmd_encoder.state_tracker.transition(&texture.resource, c.D3D12_RESOURCE_STATE_DEPTH_WRITE);

            width = view.width();
            height = view.height();
            depth_attachment = attach.*;

            dsv_handle = try cmd_encoder.command_buffer.allocateDsvDescriptor();

            d3d_device.lpVtbl.*.CreateDepthStencilView.?(
                d3d_device,
                texture.resource.d3d_resource,
                null,
                dsv_handle,
            );
        }

        cmd_encoder.state_tracker.flush(command_list);

        command_list.lpVtbl.*.OMSetRenderTargets.?(
            command_list,
            @intCast(desc.color_attachment_count),
            &rtv_handles,
            c.TRUE,
            if (desc.depth_stencil_attachment != null) &dsv_handle else null,
        );

        rtv_handle = rtv_handles;
        for (0..desc.color_attachment_count) |i| {
            const attach = desc.color_attachments.?[i];

            if (attach.load_op == .clear) {
                const clear_color = [4]f32{
                    @floatCast(attach.clear_value.r),
                    @floatCast(attach.clear_value.g),
                    @floatCast(attach.clear_value.b),
                    @floatCast(attach.clear_value.a),
                };
                command_list.lpVtbl.*.ClearRenderTargetView.?(
                    command_list,
                    rtv_handle,
                    &clear_color,
                    0,
                    null,
                );
            }

            rtv_handle.ptr += descriptor_size;
        }

        if (desc.depth_stencil_attachment) |attach| {
            var clear_flags: c.D3D12_CLEAR_FLAGS = 0;

            if (attach.depth_load_op == .clear)
                clear_flags |= c.D3D12_CLEAR_FLAG_DEPTH;
            if (attach.stencil_load_op == .clear)
                clear_flags |= c.D3D12_CLEAR_FLAG_STENCIL;

            if (clear_flags != 0) {
                command_list.lpVtbl.*.ClearDepthStencilView.?(
                    command_list,
                    dsv_handle,
                    clear_flags,
                    attach.depth_clear_value,
                    @intCast(attach.stencil_clear_value),
                    0,
                    null,
                );
            }
        }

        const viewport = c.D3D12_VIEWPORT{
            .TopLeftX = 0,
            .TopLeftY = 0,
            .Width = @floatFromInt(width),
            .Height = @floatFromInt(height),
            .MinDepth = 0,
            .MaxDepth = 1,
        };
        const scissor_rect = c.D3D12_RECT{
            .left = 0,
            .top = 0,
            .right = @intCast(width),
            .bottom = @intCast(height),
        };

        command_list.lpVtbl.*.RSSetViewports.?(command_list, 1, &viewport);
        command_list.lpVtbl.*.RSSetScissorRects.?(command_list, 1, &scissor_rect);

        // Result
        const encoder = try allocator.create(RenderPassEncoder);
        encoder.* = .{
            .command_list = command_list,
            .color_attachments = color_attachments,
            .depth_attachment = depth_attachment,
            .reference_tracker = cmd_encoder.reference_tracker,
            .state_tracker = &cmd_encoder.state_tracker,
            .vertex_buffer_views = std.mem.zeroes([limits.max_vertex_buffers]c.D3D12_VERTEX_BUFFER_VIEW),
        };
        return encoder;
    }

    pub fn deinit(encoder: *RenderPassEncoder) void {
        allocator.destroy(encoder);
    }

    pub fn draw(
        encoder: *RenderPassEncoder,
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    ) !void {
        const command_list = encoder.command_list;

        encoder.applyVertexBuffers();

        command_list.lpVtbl.*.DrawInstanced.?(
            command_list,
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    pub fn drawIndexed(
        encoder: *RenderPassEncoder,
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    ) !void {
        const command_list = encoder.command_list;

        encoder.applyVertexBuffers();

        command_list.lpVtbl.*.DrawIndexedInstanced.?(
            command_list,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub fn end(encoder: *RenderPassEncoder) !void {
        const command_list = encoder.command_list;

        for (encoder.color_attachments.slice()) |attach| {
            const view: *TextureView = @ptrCast(@alignCast(attach.view.?));

            if (attach.resolve_target) |resolve_target_raw| {
                const resolve_target: *TextureView = @ptrCast(@alignCast(resolve_target_raw));

                try encoder.reference_tracker.referenceTexture(resolve_target.texture);
                try encoder.state_tracker.transition(&view.texture.resource, c.D3D12_RESOURCE_STATE_RESOLVE_SOURCE);
                try encoder.state_tracker.transition(&resolve_target.texture.resource, c.D3D12_RESOURCE_STATE_RESOLVE_DEST);

                encoder.state_tracker.flush(command_list);

                // Format
                const resolve_d3d_resource = resolve_target.texture.resource.d3d_resource;
                const view_d3d_resource = view.texture.resource.d3d_resource;
                var d3d_desc: c.D3D12_RESOURCE_DESC = undefined;

                var format: c.DXGI_FORMAT = undefined;
                _ = resolve_d3d_resource.lpVtbl.*.GetDesc.?(resolve_d3d_resource, &d3d_desc);
                format = d3d_desc.Format;
                if (conv.dxgiFormatIsTypeless(format)) {
                    _ = view_d3d_resource.lpVtbl.*.GetDesc.?(view_d3d_resource, &d3d_desc);
                    format = d3d_desc.Format;
                    if (conv.dxgiFormatIsTypeless(format)) {
                        return error.NoTypedFormat;
                    }
                }

                command_list.lpVtbl.*.ResolveSubresource.?(
                    command_list,
                    resolve_target.texture.resource.d3d_resource,
                    resolve_target.base_subresource,
                    view.texture.resource.d3d_resource,
                    view.base_subresource,
                    format,
                );

                try encoder.state_tracker.transition(&resolve_target.texture.resource, resolve_target.texture.resource.read_state);
            }

            try encoder.state_tracker.transition(&view.texture.resource, view.texture.resource.read_state);
        }

        if (encoder.depth_attachment) |attach| {
            const view: *TextureView = @ptrCast(@alignCast(attach.view));

            try encoder.state_tracker.transition(&view.texture.resource, view.texture.resource.read_state);
        }
    }

    pub fn setBindGroup(
        encoder: *RenderPassEncoder,
        group_index: u32,
        group: *BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) !void {
        const command_list = encoder.command_list;

        try encoder.reference_tracker.referenceBindGroup(group);

        var parameter_index = encoder.group_parameter_indices[group_index];

        if (group.general_table) |table| {
            command_list.lpVtbl.*.SetGraphicsRootDescriptorTable.?(
                command_list,
                parameter_index,
                table,
            );
            parameter_index += 1;
        }

        if (group.sampler_table) |table| {
            command_list.lpVtbl.*.SetGraphicsRootDescriptorTable.?(
                command_list,
                parameter_index,
                table,
            );
            parameter_index += 1;
        }

        for (0..dynamic_offset_count) |i| {
            const dynamic_resource = group.dynamic_resources[i];
            const dynamic_offset = dynamic_offsets.?[i];

            switch (dynamic_resource.parameter_type) {
                c.D3D12_ROOT_PARAMETER_TYPE_CBV => command_list.lpVtbl.*.SetGraphicsRootConstantBufferView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                c.D3D12_ROOT_PARAMETER_TYPE_SRV => command_list.lpVtbl.*.SetGraphicsRootShaderResourceView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                c.D3D12_ROOT_PARAMETER_TYPE_UAV => command_list.lpVtbl.*.SetGraphicsRootUnorderedAccessView.?(
                    command_list,
                    parameter_index,
                    dynamic_resource.address + dynamic_offset,
                ),
                else => {},
            }

            parameter_index += 1;
        }
    }

    pub fn setIndexBuffer(
        encoder: *RenderPassEncoder,
        buffer: *Buffer,
        format: sysgpu.IndexFormat,
        offset: u64,
        size: u64,
    ) !void {
        const command_list = encoder.command_list;
        const d3d_resource = buffer.resource.d3d_resource;

        try encoder.reference_tracker.referenceBuffer(buffer);

        const d3d_size: u32 = @intCast(if (size == sysgpu.whole_size) buffer.size - offset else size);

        command_list.lpVtbl.*.IASetIndexBuffer.?(
            command_list,
            &c.D3D12_INDEX_BUFFER_VIEW{
                .BufferLocation = d3d_resource.lpVtbl.*.GetGPUVirtualAddress.?(d3d_resource) + offset,
                .SizeInBytes = d3d_size,
                .Format = conv.dxgiFormatForIndex(format),
            },
        );
    }

    pub fn setPipeline(encoder: *RenderPassEncoder, pipeline: *RenderPipeline) !void {
        const command_list = encoder.command_list;

        try encoder.reference_tracker.referenceRenderPipeline(pipeline);

        encoder.group_parameter_indices = pipeline.layout.group_parameter_indices.slice();
        encoder.vertex_strides = pipeline.vertex_strides.slice();

        command_list.lpVtbl.*.SetGraphicsRootSignature.?(
            command_list,
            pipeline.layout.root_signature,
        );

        command_list.lpVtbl.*.SetPipelineState.?(
            command_list,
            pipeline.d3d_pipeline,
        );

        command_list.lpVtbl.*.IASetPrimitiveTopology.?(
            command_list,
            pipeline.topology,
        );
    }

    pub fn setScissorRect(encoder: *RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) !void {
        const command_list = encoder.command_list;

        const scissor_rect = c.D3D12_RECT{
            .left = @intCast(x),
            .top = @intCast(y),
            .right = @intCast(x + width),
            .bottom = @intCast(y + height),
        };

        command_list.lpVtbl.*.RSSetScissorRects.?(command_list, 1, &scissor_rect);
    }

    pub fn setVertexBuffer(encoder: *RenderPassEncoder, slot: u32, buffer: *Buffer, offset: u64, size: u64) !void {
        const d3d_resource = buffer.resource.d3d_resource;
        try encoder.reference_tracker.referenceBuffer(buffer);

        var view = &encoder.vertex_buffer_views[slot];
        view.BufferLocation = d3d_resource.lpVtbl.*.GetGPUVirtualAddress.?(d3d_resource) + offset;
        view.SizeInBytes = @intCast(size);
        // StrideInBytes deferred until draw()

        encoder.vertex_apply_count = @max(encoder.vertex_apply_count, slot + 1);
    }

    pub fn setViewport(
        encoder: *RenderPassEncoder,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        min_depth: f32,
        max_depth: f32,
    ) !void {
        const command_list = encoder.command_list;

        const viewport = c.D3D12_VIEWPORT{
            .TopLeftX = x,
            .TopLeftY = y,
            .Width = width,
            .Height = height,
            .MinDepth = min_depth,
            .MaxDepth = max_depth,
        };

        command_list.lpVtbl.*.RSSetViewports.?(command_list, 1, &viewport);
    }

    // Private
    fn applyVertexBuffers(encoder: *RenderPassEncoder) void {
        if (encoder.vertex_apply_count > 0) {
            const command_list = encoder.command_list;

            for (0..encoder.vertex_apply_count) |i| {
                var view = &encoder.vertex_buffer_views[i];
                view.StrideInBytes = encoder.vertex_strides[i];
            }

            command_list.lpVtbl.*.IASetVertexBuffers.?(
                command_list,
                0,
                encoder.vertex_apply_count,
                &encoder.vertex_buffer_views,
            );

            encoder.vertex_apply_count = 0;
        }
    }
};

pub const Queue = struct {
    manager: utils.Manager(Queue) = .{},
    device: *Device,
    d3d_command_queue: *c.ID3D12CommandQueue,
    fence: *c.ID3D12Fence,
    fence_value: u64 = 0,
    fence_event: c.HANDLE,
    command_encoder: ?*CommandEncoder = null,

    pub fn init(device: *Device) !Queue {
        const d3d_device = device.d3d_device;
        var hr: c.HRESULT = undefined;

        // Command Queue
        var d3d_command_queue: *c.ID3D12CommandQueue = undefined;
        hr = d3d_device.lpVtbl.*.CreateCommandQueue.?(
            d3d_device,
            &c.D3D12_COMMAND_QUEUE_DESC{
                .Type = c.D3D12_COMMAND_LIST_TYPE_DIRECT,
                .Priority = c.D3D12_COMMAND_QUEUE_PRIORITY_NORMAL,
                .Flags = c.D3D12_COMMAND_QUEUE_FLAG_NONE,
                .NodeMask = 0,
            },
            &c.IID_ID3D12CommandQueue,
            @ptrCast(&d3d_command_queue),
        );
        if (hr != c.S_OK) {
            return error.CreateCommandQueueFailed;
        }
        errdefer _ = d3d_command_queue.lpVtbl.*.Release.?(d3d_command_queue);

        // Fence
        var fence: *c.ID3D12Fence = undefined;
        hr = d3d_device.lpVtbl.*.CreateFence.?(
            d3d_device,
            0,
            c.D3D12_FENCE_FLAG_NONE,
            &c.IID_ID3D12Fence,
            @ptrCast(&fence),
        );
        if (hr != c.S_OK) {
            return error.CreateFenceFailed;
        }
        errdefer _ = fence.lpVtbl.*.Release.?(fence);

        // Fence Event
        const fence_event = c.CreateEventW(null, c.FALSE, c.FALSE, null);
        if (fence_event == null) {
            return error.CreateEventFailed;
        }
        errdefer _ = c.CloseHandle(fence_event);

        // Result
        return .{
            .device = device,
            .d3d_command_queue = d3d_command_queue,
            .fence = fence,
            .fence_event = fence_event,
        };
    }

    pub fn deinit(queue: *Queue) void {
        const d3d_command_queue = queue.d3d_command_queue;
        const fence = queue.fence;

        queue.waitUntil(queue.fence_value);

        if (queue.command_encoder) |command_encoder| command_encoder.manager.release();
        _ = d3d_command_queue.lpVtbl.*.Release.?(d3d_command_queue);
        _ = fence.lpVtbl.*.Release.?(fence);
        _ = c.CloseHandle(queue.fence_event);
    }

    pub fn submit(queue: *Queue, command_buffers: []const *CommandBuffer) !void {
        var command_manager = &queue.device.command_manager;
        const d3d_command_queue = queue.d3d_command_queue;

        var command_lists = try std.ArrayListUnmanaged(*c.ID3D12GraphicsCommandList).initCapacity(
            allocator,
            command_buffers.len + 1,
        );
        defer command_lists.deinit(allocator);

        queue.fence_value += 1;

        if (queue.command_encoder) |command_encoder| {
            const command_buffer = try command_encoder.finish(&.{});
            command_buffer.manager.reference(); // handled in main.zig
            defer command_buffer.manager.release();

            command_lists.appendAssumeCapacity(command_buffer.command_list);
            try command_buffer.reference_tracker.submit(queue);

            command_encoder.manager.release();
            queue.command_encoder = null;
        }

        for (command_buffers) |command_buffer| {
            command_lists.appendAssumeCapacity(command_buffer.command_list);
            try command_buffer.reference_tracker.submit(queue);
        }

        d3d_command_queue.lpVtbl.*.ExecuteCommandLists.?(
            d3d_command_queue,
            @intCast(command_lists.items.len),
            @ptrCast(command_lists.items.ptr),
        );

        for (command_lists.items) |command_list| {
            command_manager.destroyCommandList(command_list);
        }

        try queue.signal();
    }

    pub fn writeBuffer(queue: *Queue, buffer: *Buffer, offset: u64, data: [*]const u8, size: u64) !void {
        const encoder = try queue.getCommandEncoder();
        try encoder.writeBuffer(buffer, offset, data, size);
    }

    pub fn writeTexture(
        queue: *Queue,
        destination: *const sysgpu.ImageCopyTexture,
        data: [*]const u8,
        data_size: usize,
        data_layout: *const sysgpu.Texture.DataLayout,
        write_size: *const sysgpu.Extent3D,
    ) !void {
        const encoder = try queue.getCommandEncoder();
        try encoder.writeTexture(destination, data, data_size, data_layout, write_size);
    }

    // Internal
    pub fn signal(queue: *Queue) !void {
        const d3d_command_queue = queue.d3d_command_queue;
        var hr: c.HRESULT = undefined;

        hr = d3d_command_queue.lpVtbl.*.Signal.?(
            d3d_command_queue,
            queue.fence,
            queue.fence_value,
        );
        if (hr != c.S_OK) {
            return error.SignalFailed;
        }
    }

    pub fn waitUntil(queue: *Queue, fence_value: u64) void {
        const fence = queue.fence;
        const fence_event = queue.fence_event;
        var hr: c.HRESULT = undefined;

        const completed_value = fence.lpVtbl.*.GetCompletedValue.?(fence);
        if (completed_value >= fence_value)
            return;

        hr = fence.lpVtbl.*.SetEventOnCompletion.?(
            fence,
            fence_value,
            fence_event,
        );
        std.debug.assert(hr == c.S_OK);

        const result = c.WaitForSingleObject(fence_event, c.INFINITE);
        std.debug.assert(result == c.WAIT_OBJECT_0);
    }

    // Private
    fn getCommandEncoder(queue: *Queue) !*CommandEncoder {
        if (queue.command_encoder) |command_encoder| return command_encoder;

        const command_encoder = try CommandEncoder.init(queue.device, &.{});
        queue.command_encoder = command_encoder;
        return command_encoder;
    }
};
