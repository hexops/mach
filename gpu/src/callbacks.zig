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

pub const CompilationInfoCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        status: CompilationInfoRequestStatus,
        compilation_info: *const CompilationInfo,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        status: CompilationInfoRequestStatus,
        compilation_info: *const CompilationInfo,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const ErrorCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        typ: ErrorType,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        typ: ErrorType,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const LoggingCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        typ: LoggingType,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        typ: LoggingType,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const RequestDeviceCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        status: RequestDeviceStatus,
        device: *Device,
        message: ?[*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        status: RequestDeviceStatus,
        device: *Device,
        message: ?[*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const RequestAdapterCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        status: RequestAdapterStatus,
        adapter: *Adapter,
        message: ?[*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        status: RequestAdapterStatus,
        adapter: *Adapter,
        message: ?[*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const CreateComputePipelineAsyncCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        status: CreatePipelineAsyncStatus,
        compute_pipeline: *ComputePipeline,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        status: CreatePipelineAsyncStatus,
        compute_pipeline: *ComputePipeline,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

pub const CreateRenderPipelineAsyncCallback = if (@import("builtin").zig_backend == .stage1)
    fn (
        status: CreatePipelineAsyncStatus,
        pipeline: *RenderPipeline,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void
else
    *const fn (
        status: CreatePipelineAsyncStatus,
        pipeline: *RenderPipeline,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;
