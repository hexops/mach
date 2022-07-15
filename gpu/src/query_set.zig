pub const QuerySet = enum(usize) {
    _,

    pub const none: QuerySet = @intToEnum(QuerySet, 0);
};
