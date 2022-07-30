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

pub const CompilationInfoCallback = fn (
    status: CompilationInfoRequestStatus,
    compilation_info: *const CompilationInfo,
    userdata: *anyopaque,
) callconv(.C) void;

pub const ErrorCallback = fn (
    typ: ErrorType,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const LoggingCallback = fn (
    typ: LoggingType,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const RequestDeviceCallback = fn (
    status: RequestDeviceStatus,
    device: *Device,
    message: ?[*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const RequestAdapterCallback = fn (
    status: RequestAdapterStatus,
    adapter: *Adapter,
    message: ?[*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const CreateComputePipelineAsyncCallback = fn (
    status: CreatePipelineAsyncStatus,
    compute_pipeline: *ComputePipeline,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const CreateRenderPipelineAsyncCallback = fn (
    status: CreatePipelineAsyncStatus,
    pipeline: *RenderPipeline,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;
