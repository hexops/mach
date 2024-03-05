### Object ordering

Backends should be a single file with object in the following order:

- Instance
- Adapter
- Surface
- SurfaceCapabilities
- Device
- SwapChain
- Buffer
- Texture
- TextureView
- Sampler
- BindGroupLayout
- BindGroup
- PipelineLayout
- ShaderModule
- ComputePipeline
- RenderPipeline
- CommandBuffer
- CommandEncoder
- ComputePassEncoder
- RenderPassEncoder
- RenderBundle
- RenderBundleEncoder
- Queue
- QuerySet

Utility objects (e.g. StateTracker should come after the closest object that "owns" them.
