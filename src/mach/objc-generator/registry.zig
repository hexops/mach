const std = @import("std");

// Types are dynamically allocated into the converter's arena so do not need a deinit
pub const Type = union(enum) {
    void,
    bool,
    int: u8,
    uint: u8,
    float: u8,
    c_short,
    c_ushort,
    c_int,
    c_uint,
    c_long,
    c_ulong,
    c_longlong,
    c_ulonglong,
    name: []const u8,
    pointer: Pointer,
    instance_type,
    function: Function,
    generic: Generic,

    pub const Pointer = struct {
        is_single: bool,
        is_const: bool,
        is_optional: bool,
        child: *Type,
    };

    pub const Function = struct {
        return_type: *Type,
        params: std.ArrayList(Type),
    };

    pub const Generic = struct {
        base_type: *Type,
        args: std.ArrayList(Type),
    };
};

pub const EnumValue = struct {
    name: []const u8,
    value: i64,
};

pub const Enum = struct {
    const Self = @This();
    const ValueList = std.ArrayList(EnumValue);

    name: []const u8,
    ty: Type,
    values: ValueList,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Enum {
        return Enum{
            .name = name,
            .ty = undefined,
            .values = ValueList.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.values.deinit();
    }
};

pub const TypeParam = struct {
    name: []const u8,

    pub fn init(name: []const u8) TypeParam {
        return TypeParam{ .name = name };
    }
};

pub const Property = struct {
    name: []const u8,
    ty: Type,

    pub fn init(name: []const u8, ty: Type) Property {
        return Property{ .name = name, .ty = ty };
    }
};

pub const Param = struct {
    name: []const u8,
    ty: Type,

    pub fn init(name: []const u8, ty: Type) Param {
        return Param{ .name = name, .ty = ty };
    }
};

pub const Method = struct {
    const Self = @This();
    const ParamList = std.ArrayList(Param);

    name: []const u8,
    instance: bool,
    return_type: Type,
    params: ParamList,

    pub fn init(name: []const u8, instance: bool, return_type: Type, params: ParamList) Method {
        return Method{
            .name = name,
            .instance = instance,
            .return_type = return_type,
            .params = params,
        };
    }

    pub fn deinit(self: *Self) void {
        self.params.deinit();
    }
};

pub const Container = struct {
    const Self = @This();
    const ContainerList = std.ArrayList(*Container);
    const TypeParamList = std.ArrayList(TypeParam);
    const PropertyList = std.ArrayList(Property);
    const MethodList = std.ArrayList(Method);

    name: []const u8,
    super: ?*Container,
    protocols: ContainerList,
    type_params: TypeParamList,
    properties: PropertyList,
    methods: MethodList,
    is_interface: bool,
    ambiguous: bool, // Same typename as protocol and interface

    pub fn init(allocator: std.mem.Allocator, name: []const u8, is_interface: bool) Container {
        return Container{
            .name = name,
            .super = null,
            .protocols = ContainerList.init(allocator),
            .type_params = TypeParamList.init(allocator),
            .properties = PropertyList.init(allocator),
            .methods = MethodList.init(allocator),
            .is_interface = is_interface,
            .ambiguous = false,
        };
    }

    pub fn deinit(self: *Self) void {
        self.protocols.deinit();
        self.type_params.deinit();
        self.properties.deinit();
        for (self.methods.items) |*method| {
            method.deinit();
        }
        self.methods.deinit();
    }
};

pub const Registry = struct {
    const Self = @This();
    const TypedefHashMap = std.StringHashMap(Type);
    const EnumHashMap = std.StringHashMap(*Enum);
    const ContainerHashMap = std.StringHashMap(*Container);

    allocator: std.mem.Allocator,
    typedefs: TypedefHashMap,
    enums: EnumHashMap,
    protocols: ContainerHashMap,
    interfaces: ContainerHashMap,

    pub fn init(allocator: std.mem.Allocator) Registry {
        return Registry{
            .allocator = allocator,
            .typedefs = TypedefHashMap.init(allocator),
            .enums = EnumHashMap.init(allocator),
            .protocols = ContainerHashMap.init(allocator),
            .interfaces = ContainerHashMap.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.typedefs.deinit();
        self.deinitMap(&self.enums);
        self.deinitMap(&self.protocols);
        self.deinitMap(&self.interfaces);
    }

    fn deinitMap(self: *Self, map: anytype) void {
        var it = map.iterator();
        while (it.next()) |entry| {
            var value = entry.value_ptr.*;
            value.deinit();
            self.allocator.destroy(value);
        }
        map.deinit();
    }

    pub fn getEnum(self: *Self, name: []const u8) !*Enum {
        var v = try self.enums.getOrPut(name);
        if (v.found_existing) {
            return v.value_ptr.*;
        } else {
            var e = try self.allocator.create(Enum);
            e.* = Enum.init(self.allocator, name);
            v.value_ptr.* = e;
            return e;
        }
    }

    pub fn getProtocol(self: *Self, name: []const u8) !*Container {
        return try self.getContainer(&self.protocols, &self.interfaces, name, false);
    }

    pub fn getInterface(self: *Self, name: []const u8) !*Container {
        return try self.getContainer(&self.interfaces, &self.protocols, name, true);
    }

    fn getContainer(
        self: *Self,
        primary: *ContainerHashMap,
        secondary: *ContainerHashMap,
        name: []const u8,
        is_interface: bool,
    ) !*Container {
        var v = try primary.getOrPut(name);
        var container: *Container = undefined;
        if (v.found_existing) {
            container = v.value_ptr.*;
        } else {
            container = try self.allocator.create(Container);
            container.* = Container.init(self.allocator, name, is_interface);
            v.value_ptr.* = container;
        }

        if (secondary.get(name)) |other| {
            other.ambiguous = true;
            container.ambiguous = true;
        }

        return container;
    }
};
