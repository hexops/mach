pub const SwapChain = enum(usize) {
    _,

    pub const none: SwapChain = @intToEnum(SwapChain, 0);
};
