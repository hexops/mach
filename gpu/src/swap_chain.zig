pub const SwapChain = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: SwapChain = @intToEnum(SwapChain, 0);
};
