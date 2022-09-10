const CompilationInfoRequestStatus = @import("types.zig").CompilationInfoRequestStatus;
const CompilationInfo = @import("types.zig").CompilationInfo;
const ErrorType = @import("types.zig").ErrorType;
const LoggingType = @import("types.zig").LoggingType;
const RequestDeviceStatus = @import("types.zig").RequestDeviceStatus;
const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
const CreatePipelineAsyncStatus = @import("types.zig").CreatePipelineAsyncStatus;
const Device = @import("device.zig").Device;
const Adapter = @import("adapter.zig").Adapter;
const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;

pub const CompilationInfoCallback = *const fn (
    status: CompilationInfoRequestStatus,
    compilation_info: *const CompilationInfo,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const ErrorCallback = *const fn (
    typ: ErrorType,
    message: [*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const LoggingCallback = *const fn (
    typ: LoggingType,
    message: [*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const RequestDeviceCallback = *const fn (
    status: RequestDeviceStatus,
    device: *Device,
    message: ?[*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const RequestAdapterCallback = *const fn (
    status: RequestAdapterStatus,
    adapter: *Adapter,
    message: ?[*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const CreateComputePipelineAsyncCallback = *const fn (
    status: CreatePipelineAsyncStatus,
    compute_pipeline: *ComputePipeline,
    message: [*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;

pub const CreateRenderPipelineAsyncCallback = *const fn (
    status: CreatePipelineAsyncStatus,
    pipeline: *RenderPipeline,
    message: [*:0]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;
