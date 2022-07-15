pub const QuerySet = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: QuerySet = @intToEnum(QuerySet, 0);
};
