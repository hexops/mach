const std = @import("std");
const builtin = @import("builtin");
const vk = @import("vulkan");

pub const BaseFunctions = vk.BaseWrapper(.{
    .createInstance = true,
    .enumerateInstanceExtensionProperties = true,
    .enumerateInstanceLayerProperties = true,
    .getInstanceProcAddr = true,
});

pub const InstanceFunctions = vk.InstanceWrapper(.{
    .createDevice = true,
    // TODO: renderdoc will not work with wayland
    // .createWaylandSurfaceKHR = builtin.target.os.tag == .linux,
    .createWin32SurfaceKHR = builtin.target.os.tag == .windows,
    .createXlibSurfaceKHR = builtin.target.os.tag == .linux,
    .destroyInstance = true,
    .destroySurfaceKHR = true,
    .enumerateDeviceExtensionProperties = true,
    .enumerateDeviceLayerProperties = true,
    .enumeratePhysicalDevices = true,
    .getDeviceProcAddr = true,
    .getPhysicalDeviceFeatures = true,
    .getPhysicalDeviceFormatProperties = true,
    .getPhysicalDeviceProperties = true,
    .getPhysicalDeviceMemoryProperties = true,
    .getPhysicalDeviceQueueFamilyProperties = true,
    .getPhysicalDeviceSurfaceCapabilitiesKHR = true,
    .getPhysicalDeviceSurfaceFormatsKHR = true,
});

pub const DeviceFunctions = vk.DeviceWrapper(.{
    .acquireNextImageKHR = true,
    .allocateCommandBuffers = true,
    .allocateDescriptorSets = true,
    .allocateMemory = true,
    .beginCommandBuffer = true,
    .bindBufferMemory = true,
    .bindImageMemory = true,
    .cmdBeginRenderPass = true,
    .cmdBindDescriptorSets = true,
    .cmdBindIndexBuffer = true,
    .cmdBindPipeline = true,
    .cmdBindVertexBuffers = true,
    .cmdCopyBuffer = true,
    .cmdCopyBufferToImage = true,
    .cmdCopyImage = true,
    .cmdDispatch = true,
    .cmdDraw = true,
    .cmdDrawIndexed = true,
    .cmdEndRenderPass = true,
    .cmdPipelineBarrier = true,
    .cmdSetScissor = true,
    .cmdSetStencilReference = true,
    .cmdSetViewport = true,
    .createBuffer = true,
    .createCommandPool = true,
    .createComputePipelines = true,
    .createDescriptorPool = true,
    .createDescriptorSetLayout = true,
    .createFence = true,
    .createFramebuffer = true,
    .createGraphicsPipelines = true,
    .createImage = true,
    .createImageView = true,
    .createPipelineLayout = true,
    .createRenderPass = true,
    .createSampler = true,
    .createSemaphore = true,
    .createShaderModule = true,
    .createSwapchainKHR = true,
    .destroyBuffer = true,
    .destroyCommandPool = true,
    .destroyDescriptorPool = true,
    .destroyDescriptorSetLayout = true,
    .destroyDevice = true,
    .destroyFence = true,
    .destroyFramebuffer = true,
    .destroyImage = true,
    .destroyImageView = true,
    .destroyPipeline = true,
    .destroyPipelineLayout = true,
    .destroyRenderPass = true,
    .destroySampler = true,
    .destroySemaphore = true,
    .destroyShaderModule = true,
    .destroySwapchainKHR = true,
    .deviceWaitIdle = true,
    .endCommandBuffer = true,
    .freeCommandBuffers = true,
    .freeDescriptorSets = true,
    .freeMemory = true,
    .getBufferMemoryRequirements = true,
    .getDeviceQueue = true,
    .getFenceStatus = true,
    .getImageMemoryRequirements = true,
    .getSwapchainImagesKHR = true,
    .mapMemory = true,
    .queuePresentKHR = true,
    .queueSubmit = true,
    .queueWaitIdle = true,
    .resetCommandBuffer = true,
    .resetFences = true,
    .unmapMemory = true,
    .updateDescriptorSets = true,
    .waitForFences = true,
});

pub const BaseLoader = *const fn (vk.Instance, [*:0]const u8) vk.PfnVoidFunction;

pub fn loadBase(baseLoader: BaseLoader) !BaseFunctions {
    return BaseFunctions.load(baseLoader) catch return error.ProcLoadingFailed;
}

pub fn loadInstance(instance: vk.Instance, instanceLoader: vk.PfnGetInstanceProcAddr) !InstanceFunctions {
    return InstanceFunctions.load(instance, instanceLoader) catch return error.ProcLoadingFailed;
}

pub fn loadDevice(device: vk.Device, deviceLoader: vk.PfnGetDeviceProcAddr) !DeviceFunctions {
    return DeviceFunctions.load(device, deviceLoader) catch return error.ProcLoadingFailed;
}
