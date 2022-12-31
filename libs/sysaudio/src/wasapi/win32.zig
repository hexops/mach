const WINAPI = @import("std").os.windows.WINAPI;
pub const Guid = extern union {
    Ints: extern struct {
        a: u32,
        b: u16,
        c: u16,
        d: [8]u8,
    },
    Bytes: [16]u8,
    const hex_offsets = switch (@import("builtin").target.cpu.arch.endian()) {
        .Big => [16]u6{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 },
        .Little => [16]u6{ 6, 4, 2, 0, 11, 9, 16, 14, 19, 21, 24, 26, 28, 30, 32, 34 },
    };
    pub fn initString(s: []const u8) Guid {
        var guid = Guid{ .Bytes = undefined };
        for (hex_offsets) |hex_offset, i| {
            guid.Bytes[i] = decodeHexByte([2]u8{ s[hex_offset], s[hex_offset + 1] });
        }
        return guid;
    }
    fn hexVal(c: u8) u4 {
        if (c <= '9') return @intCast(u4, c - '0');
        if (c >= 'a') return @intCast(u4, c + 10 - 'a');
        return @intCast(u4, c + 10 - 'A');
    }
    fn decodeHexByte(hex: [2]u8) u8 {
        return @intCast(u8, hexVal(hex[0])) << 4 | hexVal(hex[1]);
    }
    pub fn eql(riid1: Guid, riid2: Guid) bool {
        return riid1.Ints.a == riid2.Ints.a and
            riid1.Ints.b == riid2.Ints.b and
            riid1.Ints.c == riid2.Ints.c and
            @import("std").mem.eql(u8, &riid1.Ints.d, &riid2.Ints.d) and
            @import("std").mem.eql(u8, &riid1.Bytes, &riid2.Bytes);
    }
};
pub const PROPERTYKEY = extern struct {
    fmtid: Guid,
    pid: u32,
};
pub const DECIMAL = extern struct {
    wReserved: u16,
    anon1: extern union {
        anon: extern struct {
            scale: u8,
            sign: u8,
        },
        signscale: u16,
    },
    Hi32: u32,
    anon2: extern union {
        anon: extern struct {
            Lo32: u32,
            Mid32: u32,
        },
        Lo64: u64,
    },
};
pub const LARGE_INTEGER = extern union {
    anon: extern struct {
        LowPart: u32,
        HighPart: i32,
    },
    u: extern struct {
        LowPart: u32,
        HighPart: i32,
    },
    QuadPart: i64,
};
pub const ULARGE_INTEGER = extern union {
    anon: extern struct {
        LowPart: u32,
        HighPart: u32,
    },
    u: extern struct {
        LowPart: u32,
        HighPart: u32,
    },
    QuadPart: u64,
};
pub const FILETIME = extern struct {
    dwLowDateTime: u32,
    dwHighDateTime: u32,
};
pub const BOOL = i32;
pub const BSTR = *u16;
pub const PSTR = [*:0]u8;
pub const PWSTR = [*:0]u16;
pub const CHAR = u8;
pub const HRESULT = i32;
pub const S_OK = 0;
pub const S_FALSE = 1;
pub const E_NOTIMPL = -2147467263;
pub const E_OUTOFMEMORY = -2147024882;
pub const E_INVALIDARG = -2147024809;
pub const E_FAIL = -2147467259;
pub const E_UNEXPECTED = -2147418113;
pub const E_NOINTERFACE = -2147467262;
pub const E_POINTER = -2147467261;
pub const E_HANDLE = -2147024890;
pub const E_ABORT = -2147467260;
pub const E_ACCESSDENIED = -2147024891;
pub const E_BOUNDS = -2147483637;
pub const E_CHANGED_STATE = -2147483636;
pub const E_ILLEGAL_STATE_CHANGE = -2147483635;
pub const E_ILLEGAL_METHOD_CALL = -2147483634;
pub const CLASS_E_NOAGGREGATION = -2147221232;
pub const CLASS_E_CLASSNOTAVAILABLE = -2147221231;
pub const CLASS_E_NOTLICENSED = -2147221230;
pub const REGDB_E_CLASSNOTREG = -2147221164;
pub const RPC_E_CHANGED_MODE = -2147417850;
pub const SAFEARRAYBOUND = extern struct {
    cElements: u32,
    lLbound: i32,
};
pub const SAFEARRAY = extern struct {
    cDims: u16,
    fFeatures: u16,
    cbElements: u32,
    cLocks: u32,
    pvData: ?*anyopaque,
    rgsabound: [1]SAFEARRAYBOUND,
};
pub const CLIPDATA = extern struct {
    cbSize: u32,
    ulClipFmt: i32,
    pClipData: ?*u8,
};
pub const VERSIONEDSTREAM = extern struct {
    guidVersion: Guid,
    pStream: ?*IStream,
};
pub const STREAM_SEEK = enum(u32) {
    SET = 0,
    CUR = 1,
    END = 2,
};
pub const STATSTG = extern struct {
    pwcsName: ?PWSTR,
    type: u32,
    cbSize: ULARGE_INTEGER,
    mtime: FILETIME,
    ctime: FILETIME,
    atime: FILETIME,
    grfMode: u32,
    grfLocksSupported: u32,
    clsid: Guid,
    grfStateBits: u32,
    reserved: u32,
};
pub const IStream = extern struct {
    pub const VTable = extern struct {
        base: ISequentialStream.VTable,
        Seek: *const fn (
            self: *const IStream,
            dlibMove: LARGE_INTEGER,
            dwOrigin: STREAM_SEEK,
            plibNewPosition: ?*ULARGE_INTEGER,
        ) callconv(WINAPI) HRESULT,
        SetSize: *const fn (
            self: *const IStream,
            libNewSize: ULARGE_INTEGER,
        ) callconv(WINAPI) HRESULT,
        CopyTo: *const fn (
            self: *const IStream,
            pstm: ?*IStream,
            cb: ULARGE_INTEGER,
            pcbRead: ?*ULARGE_INTEGER,
            pcbWritten: ?*ULARGE_INTEGER,
        ) callconv(WINAPI) HRESULT,
        Commit: *const fn (
            self: *const IStream,
            grfCommitFlags: u32,
        ) callconv(WINAPI) HRESULT,
        Revert: *const fn (
            self: *const IStream,
        ) callconv(WINAPI) HRESULT,
        LockRegion: *const fn (
            self: *const IStream,
            libOffset: ULARGE_INTEGER,
            cb: ULARGE_INTEGER,
            dwLockType: u32,
        ) callconv(WINAPI) HRESULT,
        UnlockRegion: *const fn (
            self: *const IStream,
            libOffset: ULARGE_INTEGER,
            cb: ULARGE_INTEGER,
            dwLockType: u32,
        ) callconv(WINAPI) HRESULT,
        Stat: *const fn (
            self: *const IStream,
            pstatstg: ?*STATSTG,
            grfStatFlag: u32,
        ) callconv(WINAPI) HRESULT,
        Clone: *const fn (
            self: *const IStream,
            ppstm: ?*?*IStream,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const COINIT = u32;
pub const COINIT_MULTITHREADED = 0x0;
pub const COINIT_APARTMENTTHREADED = 0x2;
pub const COINIT_DISABLE_OLE1DDE = 0x4;
pub const COINIT_SPEED_OVER_MEMORY = 0x8;
pub const CLSCTX = u32;
pub const CLSCTX_ALL = 23;
pub extern "ole32" fn CoInitializeEx(
    pvReserved: ?*anyopaque,
    dwCoInit: COINIT,
) callconv(WINAPI) HRESULT;
pub extern "ole32" fn CoCreateInstance(
    rclsid: ?*const Guid,
    pUnkOuter: ?*IUnknown,
    dwClsContext: CLSCTX,
    riid: *const Guid,
    ppv: ?*?*anyopaque,
) callconv(WINAPI) HRESULT;
pub extern "kernel32" fn CreateEventA(
    lpEventAttributes: ?*SECURITY_ATTRIBUTES,
    bManualReset: BOOL,
    bInitialState: BOOL,
    lpName: ?[*:0]const u8,
) callconv(WINAPI) ?HANDLE;
pub extern "kernel32" fn WaitForSingleObject(
    hHandle: ?HANDLE,
    dwMilliseconds: u32,
) callconv(WINAPI) u32;
pub const INFINITE = 4294967295;
pub const SECURITY_ATTRIBUTES = extern struct {
    nLength: u32,
    lpSecurityDescriptor: ?*anyopaque,
    bInheritHandle: BOOL,
};
pub const IID_IUnknown = &Guid.initString("00000000-0000-0000-c000-000000000046");
pub const IUnknown = extern struct {
    pub const VTable = extern struct {
        QueryInterface: *const fn (
            self: *const IUnknown,
            riid: ?*const Guid,
            ppvObject: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        AddRef: *const fn (
            self: *const IUnknown,
        ) callconv(WINAPI) u32,
        Release: *const fn (
            self: *const IUnknown,
        ) callconv(WINAPI) u32,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub inline fn QueryInterface(self: *const T, riid: ?*const Guid, ppvObject: ?*?*anyopaque) HRESULT {
                return @ptrCast(*const IUnknown.VTable, self.vtable).QueryInterface(@ptrCast(*const IUnknown, self), riid, ppvObject);
            }
            pub inline fn AddRef(self: *const T) u32 {
                return @ptrCast(*const IUnknown.VTable, self.vtable).AddRef(@ptrCast(*const IUnknown, self));
            }
            pub inline fn Release(self: *const T) u32 {
                return @ptrCast(*const IUnknown.VTable, self.vtable).Release(@ptrCast(*const IUnknown, self));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const ISequentialStream = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Read: *const fn (
            self: *const ISequentialStream,
            pv: ?*anyopaque,
            cb: u32,
            pcbRead: ?*u32,
        ) callconv(WINAPI) HRESULT,
        Write: *const fn (
            self: *const ISequentialStream,
            pv: ?*const anyopaque,
            cb: u32,
            pcbWritten: ?*u32,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const CY = extern union {
    anon: extern struct {
        Lo: u32,
        Hi: i32,
    },
    int64: i64,
};
pub const CAC = extern struct {
    cElems: u32,
    pElems: ?PSTR,
};
pub const CAUB = extern struct {
    cElems: u32,
    pElems: ?*u8,
};
pub const CAI = extern struct {
    cElems: u32,
    pElems: ?*i16,
};
pub const CAUI = extern struct {
    cElems: u32,
    pElems: ?*u16,
};
pub const CAL = extern struct {
    cElems: u32,
    pElems: ?*i32,
};
pub const CAUL = extern struct {
    cElems: u32,
    pElems: ?*u32,
};
pub const CAFLT = extern struct {
    cElems: u32,
    pElems: ?*f32,
};
pub const CADBL = extern struct {
    cElems: u32,
    pElems: ?*f64,
};
pub const CACY = extern struct {
    cElems: u32,
    pElems: ?*CY,
};
pub const CADATE = extern struct {
    cElems: u32,
    pElems: ?*f64,
};
pub const CABSTR = extern struct {
    cElems: u32,
    pElems: ?*?BSTR,
};
pub const BSTRBLOB = extern struct {
    cbSize: u32,
    pData: ?*u8,
};
pub const CABSTRBLOB = extern struct {
    cElems: u32,
    pElems: ?*BSTRBLOB,
};
pub const CABOOL = extern struct {
    cElems: u32,
    pElems: ?*i16,
};
pub const CASCODE = extern struct {
    cElems: u32,
    pElems: ?*i32,
};
pub const CAPROPVARIANT = extern struct {
    cElems: u32,
    pElems: ?*PROPVARIANT,
};
pub const CAH = extern struct {
    cElems: u32,
    pElems: ?*LARGE_INTEGER,
};
pub const CAUH = extern struct {
    cElems: u32,
    pElems: ?*ULARGE_INTEGER,
};
pub const CALPSTR = extern struct {
    cElems: u32,
    pElems: ?*?PSTR,
};
pub const CALPWSTR = extern struct {
    cElems: u32,
    pElems: ?*?PWSTR,
};
pub const CAFILETIME = extern struct {
    cElems: u32,
    pElems: ?*FILETIME,
};
pub const CACLIPDATA = extern struct {
    cElems: u32,
    pElems: ?*CLIPDATA,
};
pub const CACLSID = extern struct {
    cElems: u32,
    pElems: ?*Guid,
};
pub const BLOB = extern struct {
    cbSize: u32,
    pBlobData: ?*u8,
};
pub const INVOKEKIND = enum(i32) {
    FUNC = 1,
    PROPERTYGET = 2,
    PROPERTYPUT = 4,
    PROPERTYPUTREF = 8,
};
pub const IDLDESC = extern struct {
    dwReserved: usize,
    wIDLFlags: u16,
};
pub const VARIANT = extern struct {
    anon: extern union {
        anon: extern struct {
            vt: u16,
            wReserved1: u16,
            wReserved2: u16,
            wReserved3: u16,
            anon: extern union {
                llVal: i64,
                lVal: i32,
                bVal: u8,
                iVal: i16,
                fltVal: f32,
                dblVal: f64,
                boolVal: i16,
                __OBSOLETE__VARIANT_BOOL: i16,
                scode: i32,
                cyVal: CY,
                date: f64,
                bstrVal: ?BSTR,
                punkVal: ?*IUnknown,
                pdispVal: ?*IDispatch,
                parray: ?*SAFEARRAY,
                pbVal: ?*u8,
                piVal: ?*i16,
                plVal: ?*i32,
                pllVal: ?*i64,
                pfltVal: ?*f32,
                pdblVal: ?*f64,
                pboolVal: ?*i16,
                __OBSOLETE__VARIANT_PBOOL: ?*i16,
                pscode: ?*i32,
                pcyVal: ?*CY,
                pdate: ?*f64,
                pbstrVal: ?*?BSTR,
                ppunkVal: ?*?*IUnknown,
                ppdispVal: ?*?*IDispatch,
                pparray: ?*?*SAFEARRAY,
                pvarVal: ?*VARIANT,
                byref: ?*anyopaque,
                cVal: CHAR,
                uiVal: u16,
                ulVal: u32,
                ullVal: u64,
                intVal: i32,
                uintVal: u32,
                pdecVal: ?*DECIMAL,
                pcVal: ?PSTR,
                puiVal: ?*u16,
                pulVal: ?*u32,
                pullVal: ?*u64,
                pintVal: ?*i32,
                puintVal: ?*u32,
                anon: extern struct {
                    pvRecord: ?*anyopaque,
                    pRecInfo: ?*IRecordInfo,
                },
            },
        },
        decVal: DECIMAL,
    },
};
pub const IRecordInfo = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        RecordInit: *const fn (
            self: *const IRecordInfo,
            pvNew: ?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        RecordClear: *const fn (
            self: *const IRecordInfo,
            pvExisting: ?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        RecordCopy: *const fn (
            self: *const IRecordInfo,
            pvExisting: ?*anyopaque,
            pvNew: ?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        GetGuid: *const fn (
            self: *const IRecordInfo,
            pguid: ?*Guid,
        ) callconv(WINAPI) HRESULT,
        GetName: *const fn (
            self: *const IRecordInfo,
            pbstrName: ?*?BSTR,
        ) callconv(WINAPI) HRESULT,
        GetSize: *const fn (
            self: *const IRecordInfo,
            pcbSize: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetTypeInfo: *const fn (
            self: *const IRecordInfo,
            ppTypeInfo: ?*?*ITypeInfo,
        ) callconv(WINAPI) HRESULT,
        GetField: *const fn (
            self: *const IRecordInfo,
            pvData: ?*anyopaque,
            szFieldName: ?[*:0]const u16,
            pvarField: ?*VARIANT,
        ) callconv(WINAPI) HRESULT,
        GetFieldNoCopy: *const fn (
            self: *const IRecordInfo,
            pvData: ?*anyopaque,
            szFieldName: ?[*:0]const u16,
            pvarField: ?*VARIANT,
            ppvDataCArray: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        PutField: *const fn (
            self: *const IRecordInfo,
            wFlags: u32,
            pvData: ?*anyopaque,
            szFieldName: ?[*:0]const u16,
            pvarField: ?*VARIANT,
        ) callconv(WINAPI) HRESULT,
        PutFieldNoCopy: *const fn (
            self: *const IRecordInfo,
            wFlags: u32,
            pvData: ?*anyopaque,
            szFieldName: ?[*:0]const u16,
            pvarField: ?*VARIANT,
        ) callconv(WINAPI) HRESULT,
        GetFieldNames: *const fn (
            self: *const IRecordInfo,
            pcNames: ?*u32,
            rgBstrNames: [*]?BSTR,
        ) callconv(WINAPI) HRESULT,
        IsMatchingType: *const fn (
            self: *const IRecordInfo,
            pRecordInfo: ?*IRecordInfo,
        ) callconv(WINAPI) BOOL,
        RecordCreate: *const fn (
            self: *const IRecordInfo,
        ) callconv(WINAPI) ?*anyopaque,
        RecordCreateCopy: *const fn (
            self: *const IRecordInfo,
            pvSource: ?*anyopaque,
            ppvDest: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        RecordDestroy: *const fn (
            self: *const IRecordInfo,
            pvRecord: ?*anyopaque,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const PARAMDESCEX = extern struct {
    cBytes: u32,
    varDefaultValue: VARIANT,
};
pub const PARAMDESC = extern struct {
    pparamdescex: ?*PARAMDESCEX,
    wParamFlags: u16,
};
pub const ARRAYDESC = extern struct {
    tdescElem: TYPEDESC,
    cDims: u16,
    rgbounds: [1]SAFEARRAYBOUND,
};
pub const TYPEDESC = extern struct {
    anon: extern union {
        lptdesc: ?*TYPEDESC,
        lpadesc: ?*ARRAYDESC,
        hreftype: u32,
    },
    vt: u16,
};
pub const ELEMDESC = extern struct {
    tdesc: TYPEDESC,
    anon: extern union {
        idldesc: IDLDESC,
        paramdesc: PARAMDESC,
    },
};
pub const CALLCONV = enum(i32) {
    FASTCALL = 0,
    CDECL = 1,
    MSCPASCAL = 2,
    MACPASCAL = 3,
    STDCALL = 4,
    FPFASTCALL = 5,
    SYSCALL = 6,
    MPWCDECL = 7,
    MPWPASCAL = 8,
    MAX = 9,
};
pub const FUNCKIND = enum(i32) {
    VIRTUAL = 0,
    PUREVIRTUAL = 1,
    NONVIRTUAL = 2,
    STATIC = 3,
    DISPATCH = 4,
};
pub const FUNCDESC = extern struct {
    memid: i32,
    lprgscode: ?*i32,
    lprgelemdescParam: ?*ELEMDESC,
    funckind: FUNCKIND,
    invkind: INVOKEKIND,
    @"callconv": CALLCONV,
    cParams: i16,
    cParamsOpt: i16,
    oVft: i16,
    cScodes: i16,
    elemdescFunc: ELEMDESC,
    wFuncFlags: u16,
};
pub const TYPEATTR = extern struct {
    guid: Guid,
    lcid: u32,
    dwReserved: u32,
    memidConstructor: i32,
    memidDestructor: i32,
    lpstrSchema: ?PWSTR,
    cbSizeInstance: u32,
    typekind: TYPEKIND,
    cFuncs: u16,
    cVars: u16,
    cImplTypes: u16,
    cbSizeVft: u16,
    cbAlignment: u16,
    wTypeFlags: u16,
    wMajorVerNum: u16,
    wMinorVerNum: u16,
    tdescAlias: TYPEDESC,
    idldescType: IDLDESC,
};
pub const TYPEKIND = enum(i32) {
    ENUM = 0,
    RECORD = 1,
    MODULE = 2,
    INTERFACE = 3,
    DISPATCH = 4,
    COCLASS = 5,
    ALIAS = 6,
    UNION = 7,
    MAX = 8,
};
pub const DESCKIND = enum(i32) {
    NONE = 0,
    FUNCDESC = 1,
    VARDESC = 2,
    TYPECOMP = 3,
    IMPLICITAPPOBJ = 4,
    MAX = 5,
};
pub const BINDPTR = extern union {
    lpfuncdesc: ?*FUNCDESC,
    lpvardesc: ?*VARDESC,
    lptcomp: ?*ITypeComp,
};
pub const VARDESC = extern struct {
    memid: i32,
    lpstrSchema: ?PWSTR,
    anon: extern union {
        oInst: u32,
        lpvarValue: ?*VARIANT,
    },
    elemdescVar: ELEMDESC,
    wVarFlags: u16,
    varkind: VARKIND,
};
pub const VARKIND = enum(i32) {
    PERINSTANCE = 0,
    STATIC = 1,
    CONST = 2,
    DISPATCH = 3,
};
pub const ITypeComp = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Bind: *const fn (
            self: *const ITypeComp,
            szName: ?PWSTR,
            lHashVal: u32,
            wFlags: u16,
            ppTInfo: ?*?*ITypeInfo,
            pDescKind: ?*DESCKIND,
            pBindPtr: ?*BINDPTR,
        ) callconv(WINAPI) HRESULT,
        BindType: *const fn (
            self: *const ITypeComp,
            szName: ?PWSTR,
            lHashVal: u32,
            ppTInfo: ?*?*ITypeInfo,
            ppTComp: ?*?*ITypeComp,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const DISPPARAMS = extern struct {
    rgvarg: ?*VARIANT,
    rgdispidNamedArgs: ?*i32,
    cArgs: u32,
    cNamedArgs: u32,
};
pub const EXCEPINFO = extern struct {
    wCode: u16,
    wReserved: u16,
    bstrSource: ?BSTR,
    bstrDescription: ?BSTR,
    bstrHelpFile: ?BSTR,
    dwHelpContext: u32,
    pvReserved: ?*anyopaque,
    pfnDeferredFillIn: ?LPEXCEPFINO_DEFERRED_FILLIN,
    scode: i32,
};
pub const LPEXCEPFINO_DEFERRED_FILLIN = *const fn (
    pExcepInfo: ?*EXCEPINFO,
) callconv(WINAPI) HRESULT;
pub const ITypeInfo = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetTypeAttr: *const fn (
            self: *const ITypeInfo,
            ppTypeAttr: ?*?*TYPEATTR,
        ) callconv(WINAPI) HRESULT,
        GetTypeComp: *const fn (
            self: *const ITypeInfo,
            ppTComp: ?*?*ITypeComp,
        ) callconv(WINAPI) HRESULT,
        GetFuncDesc: *const fn (
            self: *const ITypeInfo,
            index: u32,
            ppFuncDesc: ?*?*FUNCDESC,
        ) callconv(WINAPI) HRESULT,
        GetVarDesc: *const fn (
            self: *const ITypeInfo,
            index: u32,
            ppVarDesc: ?*?*VARDESC,
        ) callconv(WINAPI) HRESULT,
        GetNames: *const fn (
            self: *const ITypeInfo,
            memid: i32,
            rgBstrNames: [*]?BSTR,
            cMaxNames: u32,
            pcNames: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetRefTypeOfImplType: *const fn (
            self: *const ITypeInfo,
            index: u32,
            pRefType: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetImplTypeFlags: *const fn (
            self: *const ITypeInfo,
            index: u32,
            pImplTypeFlags: ?*i32,
        ) callconv(WINAPI) HRESULT,
        GetIDsOfNames: *const fn (
            self: *const ITypeInfo,
            rgszNames: [*]?PWSTR,
            cNames: u32,
            pMemId: [*]i32,
        ) callconv(WINAPI) HRESULT,
        Invoke: *const fn (
            self: *const ITypeInfo,
            pvInstance: ?*anyopaque,
            memid: i32,
            wFlags: u16,
            pDispParams: ?*DISPPARAMS,
            pVarResult: ?*VARIANT,
            pExcepInfo: ?*EXCEPINFO,
            puArgErr: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetDocumentation: *const fn (
            self: *const ITypeInfo,
            memid: i32,
            pBstrName: ?*?BSTR,
            pBstrDocString: ?*?BSTR,
            pdwHelpContext: ?*u32,
            pBstrHelpFile: ?*?BSTR,
        ) callconv(WINAPI) HRESULT,
        GetDllEntry: *const fn (
            self: *const ITypeInfo,
            memid: i32,
            invKind: INVOKEKIND,
            pBstrDllName: ?*?BSTR,
            pBstrName: ?*?BSTR,
            pwOrdinal: ?*u16,
        ) callconv(WINAPI) HRESULT,
        GetRefTypeInfo: *const fn (
            self: *const ITypeInfo,
            hRefType: u32,
            ppTInfo: ?*?*ITypeInfo,
        ) callconv(WINAPI) HRESULT,
        AddressOfMember: *const fn (
            self: *const ITypeInfo,
            memid: i32,
            invKind: INVOKEKIND,
            ppv: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        CreateInstance: *const fn (
            self: *const ITypeInfo,
            pUnkOuter: ?*IUnknown,
            riid: ?*const Guid,
            ppvObj: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        GetMops: *const fn (
            self: *const ITypeInfo,
            memid: i32,
            pBstrMops: ?*?BSTR,
        ) callconv(WINAPI) HRESULT,
        GetContainingTypeLib: *const fn (
            self: *const ITypeInfo,
            ppTLib: ?*?*ITypeLib,
            pIndex: ?*u32,
        ) callconv(WINAPI) HRESULT,
        ReleaseTypeAttr: *const fn (
            self: *const ITypeInfo,
            pTypeAttr: ?*TYPEATTR,
        ) callconv(WINAPI) void,
        ReleaseFuncDesc: *const fn (
            self: *const ITypeInfo,
            pFuncDesc: ?*FUNCDESC,
        ) callconv(WINAPI) void,
        ReleaseVarDesc: *const fn (
            self: *const ITypeInfo,
            pVarDesc: ?*VARDESC,
        ) callconv(WINAPI) void,
    };
    vtable: *const VTable,
};
pub const SYSKIND = enum(i32) {
    WIN16 = 0,
    WIN32 = 1,
    MAC = 2,
    WIN64 = 3,
};
pub const TLIBATTR = extern struct {
    guid: Guid,
    lcid: u32,
    syskind: SYSKIND,
    wMajorVerNum: u16,
    wMinorVerNum: u16,
    wLibFlags: u16,
};
pub const ITypeLib = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetTypeInfoCount: *const fn (
            self: *const ITypeLib,
        ) callconv(WINAPI) u32,
        GetTypeInfo: *const fn (
            self: *const ITypeLib,
            index: u32,
            ppTInfo: ?*?*ITypeInfo,
        ) callconv(WINAPI) HRESULT,
        GetTypeInfoType: *const fn (
            self: *const ITypeLib,
            index: u32,
            pTKind: ?*TYPEKIND,
        ) callconv(WINAPI) HRESULT,
        GetTypeInfoOfGuid: *const fn (
            self: *const ITypeLib,
            guid: ?*const Guid,
            ppTinfo: ?*?*ITypeInfo,
        ) callconv(WINAPI) HRESULT,
        GetLibAttr: *const fn (
            self: *const ITypeLib,
            ppTLibAttr: ?*?*TLIBATTR,
        ) callconv(WINAPI) HRESULT,
        GetTypeComp: *const fn (
            self: *const ITypeLib,
            ppTComp: ?*?*ITypeComp,
        ) callconv(WINAPI) HRESULT,
        GetDocumentation: *const fn (
            self: *const ITypeLib,
            index: i32,
            pBstrName: ?*?BSTR,
            pBstrDocString: ?*?BSTR,
            pdwHelpContext: ?*u32,
            pBstrHelpFile: ?*?BSTR,
        ) callconv(WINAPI) HRESULT,
        IsName: *const fn (
            self: *const ITypeLib,
            szNameBuf: ?PWSTR,
            lHashVal: u32,
            pfName: ?*BOOL,
        ) callconv(WINAPI) HRESULT,
        FindName: *const fn (
            self: *const ITypeLib,
            szNameBuf: ?PWSTR,
            lHashVal: u32,
            ppTInfo: [*]?*ITypeInfo,
            rgMemId: [*]i32,
            pcFound: ?*u16,
        ) callconv(WINAPI) HRESULT,
        ReleaseTLibAttr: *const fn (
            self: *const ITypeLib,
            pTLibAttr: ?*TLIBATTR,
        ) callconv(WINAPI) void,
    };
    vtable: *const VTable,
};
pub const IDispatch = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetTypeInfoCount: *const fn (
            self: *const IDispatch,
            pctinfo: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetTypeInfo: *const fn (
            self: *const IDispatch,
            iTInfo: u32,
            lcid: u32,
            ppTInfo: ?*?*ITypeInfo,
        ) callconv(WINAPI) HRESULT,
        GetIDsOfNames: *const fn (
            self: *const IDispatch,
            riid: ?*const Guid,
            rgszNames: [*]?PWSTR,
            cNames: u32,
            lcid: u32,
            rgDispId: [*]i32,
        ) callconv(WINAPI) HRESULT,
        Invoke: *const fn (
            self: *const IDispatch,
            dispIdMember: i32,
            riid: ?*const Guid,
            lcid: u32,
            wFlags: u16,
            pDispParams: ?*DISPPARAMS,
            pVarResult: ?*VARIANT,
            pExcepInfo: ?*EXCEPINFO,
            puArgErr: ?*u32,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const IEnumSTATSTG = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Next: *const fn (
            self: *const IEnumSTATSTG,
            celt: u32,
            rgelt: [*]STATSTG,
            pceltFetched: ?*u32,
        ) callconv(WINAPI) HRESULT,
        Skip: *const fn (
            self: *const IEnumSTATSTG,
            celt: u32,
        ) callconv(WINAPI) HRESULT,
        Reset: *const fn (
            self: *const IEnumSTATSTG,
        ) callconv(WINAPI) HRESULT,
        Clone: *const fn (
            self: *const IEnumSTATSTG,
            ppenum: ?*?*IEnumSTATSTG,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const IStorage = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        CreateStream: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            grfMode: u32,
            reserved1: u32,
            reserved2: u32,
            ppstm: ?*?*IStream,
        ) callconv(WINAPI) HRESULT,
        OpenStream: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            reserved1: ?*anyopaque,
            grfMode: u32,
            reserved2: u32,
            ppstm: ?*?*IStream,
        ) callconv(WINAPI) HRESULT,
        CreateStorage: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            grfMode: u32,
            reserved1: u32,
            reserved2: u32,
            ppstg: ?*?*IStorage,
        ) callconv(WINAPI) HRESULT,
        OpenStorage: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            pstgPriority: ?*IStorage,
            grfMode: u32,
            snbExclude: ?*?*u16,
            reserved: u32,
            ppstg: ?*?*IStorage,
        ) callconv(WINAPI) HRESULT,
        CopyTo: *const fn (
            self: *const IStorage,
            ciidExclude: u32,
            rgiidExclude: ?[*]const Guid,
            snbExclude: ?*?*u16,
            pstgDest: ?*IStorage,
        ) callconv(WINAPI) HRESULT,
        MoveElementTo: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            pstgDest: ?*IStorage,
            pwcsNewName: ?[*:0]const u16,
            grfFlags: u32,
        ) callconv(WINAPI) HRESULT,
        Commit: *const fn (
            self: *const IStorage,
            grfCommitFlags: u32,
        ) callconv(WINAPI) HRESULT,
        Revert: *const fn (
            self: *const IStorage,
        ) callconv(WINAPI) HRESULT,
        EnumElements: *const fn (
            self: *const IStorage,
            reserved1: u32,
            reserved2: ?*anyopaque,
            reserved3: u32,
            ppenum: ?*?*IEnumSTATSTG,
        ) callconv(WINAPI) HRESULT,
        DestroyElement: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
        ) callconv(WINAPI) HRESULT,
        RenameElement: *const fn (
            self: *const IStorage,
            pwcsOldName: ?[*:0]const u16,
            pwcsNewName: ?[*:0]const u16,
        ) callconv(WINAPI) HRESULT,
        SetElementTimes: *const fn (
            self: *const IStorage,
            pwcsName: ?[*:0]const u16,
            pctime: ?*const FILETIME,
            patime: ?*const FILETIME,
            pmtime: ?*const FILETIME,
        ) callconv(WINAPI) HRESULT,
        SetClass: *const fn (
            self: *const IStorage,
            clsid: ?*const Guid,
        ) callconv(WINAPI) HRESULT,
        SetStateBits: *const fn (
            self: *const IStorage,
            grfStateBits: u32,
            grfMask: u32,
        ) callconv(WINAPI) HRESULT,
        Stat: *const fn (
            self: *const IStorage,
            pstatstg: ?*STATSTG,
            grfStatFlag: u32,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
};
pub const PROPVARIANT = extern struct {
    anon: extern union {
        anon: extern struct {
            vt: u16,
            wReserved1: u16,
            wReserved2: u16,
            wReserved3: u16,
            anon: extern union {
                cVal: CHAR,
                bVal: u8,
                iVal: i16,
                uiVal: u16,
                lVal: i32,
                ulVal: u32,
                intVal: i32,
                uintVal: u32,
                hVal: LARGE_INTEGER,
                uhVal: ULARGE_INTEGER,
                fltVal: f32,
                dblVal: f64,
                boolVal: i16,
                __OBSOLETE__VARIANT_BOOL: i16,
                scode: i32,
                cyVal: CY,
                date: f64,
                filetime: FILETIME,
                puuid: ?*Guid,
                pclipdata: ?*CLIPDATA,
                bstrVal: ?BSTR,
                bstrblobVal: BSTRBLOB,
                blob: BLOB,
                pszVal: ?PSTR,
                pwszVal: ?PWSTR,
                punkVal: ?*IUnknown,
                pdispVal: ?*IDispatch,
                pStream: ?*IStream,
                pStorage: ?*IStorage,
                pVersionedStream: ?*VERSIONEDSTREAM,
                parray: ?*SAFEARRAY,
                cac: CAC,
                caub: CAUB,
                cai: CAI,
                caui: CAUI,
                cal: CAL,
                caul: CAUL,
                cah: CAH,
                cauh: CAUH,
                caflt: CAFLT,
                cadbl: CADBL,
                cabool: CABOOL,
                cascode: CASCODE,
                cacy: CACY,
                cadate: CADATE,
                cafiletime: CAFILETIME,
                cauuid: CACLSID,
                caclipdata: CACLIPDATA,
                cabstr: CABSTR,
                cabstrblob: CABSTRBLOB,
                calpstr: CALPSTR,
                calpwstr: CALPWSTR,
                capropvar: CAPROPVARIANT,
                pcVal: ?PSTR,
                pbVal: ?*u8,
                piVal: ?*i16,
                puiVal: ?*u16,
                plVal: ?*i32,
                pulVal: ?*u32,
                pintVal: ?*i32,
                puintVal: ?*u32,
                pfltVal: ?*f32,
                pdblVal: ?*f64,
                pboolVal: ?*i16,
                pdecVal: ?*DECIMAL,
                pscode: ?*i32,
                pcyVal: ?*CY,
                pdate: ?*f64,
                pbstrVal: ?*?BSTR,
                ppunkVal: ?*?*IUnknown,
                ppdispVal: ?*?*IDispatch,
                pparray: ?*?*SAFEARRAY,
                pvarVal: ?*PROPVARIANT,
            },
        },
        decVal: DECIMAL,
    },
};
pub const WAVEFORMATEX = extern struct {
    wFormatTag: u16 align(1),
    nChannels: u16 align(1),
    nSamplesPerSec: u32 align(1),
    nAvgBytesPerSec: u32 align(1),
    nBlockAlign: u16 align(1),
    wBitsPerSample: u16 align(1),
    cbSize: u16 align(1),
};
pub const WAVEFORMATEXTENSIBLE = extern struct {
    Format: WAVEFORMATEX align(1),
    Samples: extern union {
        wValidBitsPerSample: u16 align(1),
        wSamplesPerBlock: u16 align(1),
        wReserved: u16 align(1),
    },
    dwChannelMask: u32 align(1),
    SubFormat: Guid align(1),
};
pub const CLSID_MMDeviceEnumerator = &Guid.initString("bcde0395-e52f-467c-8e3d-c4579291692e");
pub const DIRECTX_AUDIO_ACTIVATION_PARAMS = extern struct {
    cbDirectXAudioActivationParams: u32,
    guidAudioSession: Guid,
    dwAudioStreamFlags: u32,
};
pub const DataFlow = enum(i32) {
    render = 0,
    capture = 1,
    all = 2,
};
pub const Role = enum(i32) {
    console = 0,
    multimedia = 1,
    communications = 2,
};
pub const AUDCLNT_SHAREMODE = enum(i32) {
    SHARED = 0,
    EXCLUSIVE = 1,
};
pub const HANDLE = @import("std").os.windows.HANDLE;
pub const IID_IAudioClient = &Guid.initString("1cb9ad4c-dbfa-4c32-b178-c2f568a703b2");
pub const IAudioClient = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Initialize: *const fn (
            self: *const IAudioClient,
            ShareMode: AUDCLNT_SHAREMODE,
            StreamFlags: u32,
            hnsBufferDuration: i64,
            hnsPeriodicity: i64,
            pFormat: ?*const WAVEFORMATEX,
            AudioSessionGuid: ?*const Guid,
        ) callconv(WINAPI) HRESULT,
        GetBufferSize: *const fn (
            self: *const IAudioClient,
            pNumBufferFrames: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetStreamLatency: *const fn (
            self: *const IAudioClient,
            phnsLatency: ?*i64,
        ) callconv(WINAPI) HRESULT,
        GetCurrentPadding: *const fn (
            self: *const IAudioClient,
            pNumPaddingFrames: ?*u32,
        ) callconv(WINAPI) HRESULT,
        IsFormatSupported: *const fn (
            self: *const IAudioClient,
            ShareMode: AUDCLNT_SHAREMODE,
            pFormat: ?*const WAVEFORMATEX,
            ppClosestMatch: ?*?*WAVEFORMATEX,
        ) callconv(WINAPI) HRESULT,
        GetMixFormat: *const fn (
            self: *const IAudioClient,
            ppDeviceFormat: ?*?*WAVEFORMATEX,
        ) callconv(WINAPI) HRESULT,
        GetDevicePeriod: *const fn (
            self: *const IAudioClient,
            phnsDefaultDevicePeriod: ?*i64,
            phnsMinimumDevicePeriod: ?*i64,
        ) callconv(WINAPI) HRESULT,
        Start: *const fn (
            self: *const IAudioClient,
        ) callconv(WINAPI) HRESULT,
        Stop: *const fn (
            self: *const IAudioClient,
        ) callconv(WINAPI) HRESULT,
        Reset: *const fn (
            self: *const IAudioClient,
        ) callconv(WINAPI) HRESULT,
        SetEventHandle: *const fn (
            self: *const IAudioClient,
            eventHandle: ?HANDLE,
        ) callconv(WINAPI) HRESULT,
        GetService: *const fn (
            self: *const IAudioClient,
            riid: ?*const Guid,
            ppv: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn Initialize(self: *const T, ShareMode: AUDCLNT_SHAREMODE, StreamFlags: u32, hnsBufferDuration: i64, hnsPeriodicity: i64, pFormat: ?*const WAVEFORMATEX, AudioSessionGuid: ?*const Guid) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).Initialize(@ptrCast(*const IAudioClient, self), ShareMode, StreamFlags, hnsBufferDuration, hnsPeriodicity, pFormat, AudioSessionGuid);
            }
            pub inline fn GetBufferSize(self: *const T, pNumBufferFrames: ?*u32) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetBufferSize(@ptrCast(*const IAudioClient, self), pNumBufferFrames);
            }
            pub inline fn GetStreamLatency(self: *const T, phnsLatency: ?*i64) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetStreamLatency(@ptrCast(*const IAudioClient, self), phnsLatency);
            }
            pub inline fn GetCurrentPadding(self: *const T, pNumPaddingFrames: ?*u32) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetCurrentPadding(@ptrCast(*const IAudioClient, self), pNumPaddingFrames);
            }
            pub inline fn IsFormatSupported(self: *const T, ShareMode: AUDCLNT_SHAREMODE, pFormat: ?*const WAVEFORMATEX, ppClosestMatch: ?*?*WAVEFORMATEX) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).IsFormatSupported(@ptrCast(*const IAudioClient, self), ShareMode, pFormat, ppClosestMatch);
            }
            pub inline fn GetMixFormat(self: *const T, ppDeviceFormat: ?*?*WAVEFORMATEX) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetMixFormat(@ptrCast(*const IAudioClient, self), ppDeviceFormat);
            }
            pub inline fn GetDevicePeriod(self: *const T, phnsDefaultDevicePeriod: ?*i64, phnsMinimumDevicePeriod: ?*i64) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetDevicePeriod(@ptrCast(*const IAudioClient, self), phnsDefaultDevicePeriod, phnsMinimumDevicePeriod);
            }
            pub inline fn Start(self: *const T) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).Start(@ptrCast(*const IAudioClient, self));
            }
            pub inline fn Stop(self: *const T) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).Stop(@ptrCast(*const IAudioClient, self));
            }
            pub inline fn Reset(self: *const T) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).Reset(@ptrCast(*const IAudioClient, self));
            }
            pub inline fn SetEventHandle(self: *const T, eventHandle: ?HANDLE) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).SetEventHandle(@ptrCast(*const IAudioClient, self), eventHandle);
            }
            pub inline fn GetService(self: *const T, riid: ?*const Guid, ppv: ?*?*anyopaque) HRESULT {
                return @ptrCast(*const IAudioClient.VTable, self.vtable).GetService(@ptrCast(*const IAudioClient, self), riid, ppv);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const AUDCLNT_STREAMOPTIONS = enum(u32) {
    NONE = 0,
    RAW = 1,
    MATCH_FORMAT = 2,
    AMBISONICS = 4,
};
pub const AudioClientProperties = extern struct {
    cbSize: u32,
    bIsOffload: BOOL,
    eCategory: AUDIO_STREAM_CATEGORY,
    Options: AUDCLNT_STREAMOPTIONS,
};
pub const AUDIO_STREAM_CATEGORY = enum(i32) {
    Other = 0,
    ForegroundOnlyMedia = 1,
    Communications = 3,
    Alerts = 4,
    SoundEffects = 5,
    GameEffects = 6,
    GameMedia = 7,
    GameChat = 8,
    Speech = 9,
    Movie = 10,
    Media = 11,
    FarFieldSpeech = 12,
    UniformSpeech = 13,
    VoiceTyping = 14,
};
const IID_IAudioClient2 = &Guid.initString("726778cd-f60a-4eda-82de-e47610cd78aa");
pub const IAudioClient2 = extern struct {
    pub const VTable = extern struct {
        base: IAudioClient.VTable,
        IsOffloadCapable: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient2,
                Category: AUDIO_STREAM_CATEGORY,
                pbOffloadCapable: ?*BOOL,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient2,
                Category: AUDIO_STREAM_CATEGORY,
                pbOffloadCapable: ?*BOOL,
            ) callconv(WINAPI) HRESULT,
        },
        SetClientProperties: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient2,
                pProperties: ?*const AudioClientProperties,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient2,
                pProperties: ?*const AudioClientProperties,
            ) callconv(WINAPI) HRESULT,
        },
        GetBufferSizeLimits: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient2,
                pFormat: ?*const WAVEFORMATEX,
                bEventDriven: BOOL,
                phnsMinBufferDuration: ?*i64,
                phnsMaxBufferDuration: ?*i64,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient2,
                pFormat: ?*const WAVEFORMATEX,
                bEventDriven: BOOL,
                phnsMinBufferDuration: ?*i64,
                phnsMaxBufferDuration: ?*i64,
            ) callconv(WINAPI) HRESULT,
        },
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IAudioClient.MethodMixin(T);
            pub inline fn IsOffloadCapable(self: *const T, Category: AUDIO_STREAM_CATEGORY, pbOffloadCapable: ?*BOOL) HRESULT {
                return @ptrCast(*const IAudioClient2.VTable, self.vtable).IsOffloadCapable(@ptrCast(*const IAudioClient2, self), Category, pbOffloadCapable);
            }
            pub inline fn SetClientProperties(self: *const T, pProperties: ?*const AudioClientProperties) HRESULT {
                return @ptrCast(*const IAudioClient2.VTable, self.vtable).SetClientProperties(@ptrCast(*const IAudioClient2, self), pProperties);
            }
            pub inline fn GetBufferSizeLimits(self: *const T, pFormat: ?*const WAVEFORMATEX, bEventDriven: BOOL, phnsMinBufferDuration: ?*i64, phnsMaxBufferDuration: ?*i64) HRESULT {
                return @ptrCast(*const IAudioClient2.VTable, self.vtable).GetBufferSizeLimits(@ptrCast(*const IAudioClient2, self), pFormat, bEventDriven, phnsMinBufferDuration, phnsMaxBufferDuration);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_IAudioClient3 = &Guid.initString("7ed4ee07-8e67-4cd4-8c1a-2b7a5987ad42");
pub const IAudioClient3 = extern struct {
    pub const VTable = extern struct {
        base: IAudioClient2.VTable,
        GetSharedModeEnginePeriod: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient3,
                pFormat: ?*const WAVEFORMATEX,
                pDefaultPeriodInFrames: ?*u32,
                pFundamentalPeriodInFrames: ?*u32,
                pMinPeriodInFrames: ?*u32,
                pMaxPeriodInFrames: ?*u32,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient3,
                pFormat: ?*const WAVEFORMATEX,
                pDefaultPeriodInFrames: ?*u32,
                pFundamentalPeriodInFrames: ?*u32,
                pMinPeriodInFrames: ?*u32,
                pMaxPeriodInFrames: ?*u32,
            ) callconv(WINAPI) HRESULT,
        },
        GetCurrentSharedModeEnginePeriod: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient3,
                ppFormat: ?*?*WAVEFORMATEX,
                pCurrentPeriodInFrames: ?*u32,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient3,
                ppFormat: ?*?*WAVEFORMATEX,
                pCurrentPeriodInFrames: ?*u32,
            ) callconv(WINAPI) HRESULT,
        },
        InitializeSharedAudioStream: switch (@import("builtin").zig_backend) {
            .stage1 => fn (
                self: *const IAudioClient3,
                StreamFlags: u32,
                PeriodInFrames: u32,
                pFormat: ?*const WAVEFORMATEX,
                AudioSessionGuid: ?*const Guid,
            ) callconv(WINAPI) HRESULT,
            else => *const fn (
                self: *const IAudioClient3,
                StreamFlags: u32,
                PeriodInFrames: u32,
                pFormat: ?*const WAVEFORMATEX,
                AudioSessionGuid: ?*const Guid,
            ) callconv(WINAPI) HRESULT,
        },
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IAudioClient2.MethodMixin(T);
            pub inline fn GetSharedModeEnginePeriod(self: *const T, pFormat: ?*const WAVEFORMATEX, pDefaultPeriodInFrames: ?*u32, pFundamentalPeriodInFrames: ?*u32, pMinPeriodInFrames: ?*u32, pMaxPeriodInFrames: ?*u32) HRESULT {
                return @ptrCast(*const IAudioClient3.VTable, self.vtable).GetSharedModeEnginePeriod(@ptrCast(*const IAudioClient3, self), pFormat, pDefaultPeriodInFrames, pFundamentalPeriodInFrames, pMinPeriodInFrames, pMaxPeriodInFrames);
            }
            pub inline fn GetCurrentSharedModeEnginePeriod(self: *const T, ppFormat: ?*?*WAVEFORMATEX, pCurrentPeriodInFrames: ?*u32) HRESULT {
                return @ptrCast(*const IAudioClient3.VTable, self.vtable).GetCurrentSharedModeEnginePeriod(@ptrCast(*const IAudioClient3, self), ppFormat, pCurrentPeriodInFrames);
            }
            pub inline fn InitializeSharedAudioStream(self: *const T, StreamFlags: u32, PeriodInFrames: u32, pFormat: ?*const WAVEFORMATEX, AudioSessionGuid: ?*const Guid) HRESULT {
                return @ptrCast(*const IAudioClient3.VTable, self.vtable).InitializeSharedAudioStream(@ptrCast(*const IAudioClient3, self), StreamFlags, PeriodInFrames, pFormat, AudioSessionGuid);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub extern "ole32" fn CoTaskMemFree(pv: ?*anyopaque) callconv(WINAPI) void;
pub const IID_IAudioRenderClient = &Guid.initString("f294acfc-3146-4483-a7bf-addca7c260e2");
pub const IAudioRenderClient = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetBuffer: *const fn (
            self: *const IAudioRenderClient,
            NumFramesRequested: u32,
            ppData: ?*?*u8,
        ) callconv(WINAPI) HRESULT,
        ReleaseBuffer: *const fn (
            self: *const IAudioRenderClient,
            NumFramesWritten: u32,
            dwFlags: u32,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetBuffer(self: *const T, NumFramesRequested: u32, ppData: ?*?*u8) HRESULT {
                return @ptrCast(*const IAudioRenderClient.VTable, self.vtable).GetBuffer(@ptrCast(*const IAudioRenderClient, self), NumFramesRequested, ppData);
            }
            pub inline fn ReleaseBuffer(self: *const T, NumFramesWritten: u32, dwFlags: u32) HRESULT {
                return @ptrCast(*const IAudioRenderClient.VTable, self.vtable).ReleaseBuffer(@ptrCast(*const IAudioRenderClient, self), NumFramesWritten, dwFlags);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_ISimpleAudioVolume = &Guid.initString("87ce5498-68d6-44e5-9215-6da47ef883d8");
pub const ISimpleAudioVolume = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        SetMasterVolume: *const fn (
            self: *const ISimpleAudioVolume,
            fLevel: f32,
            EventContext: ?*const Guid,
        ) callconv(WINAPI) HRESULT,
        GetMasterVolume: *const fn (
            self: *const ISimpleAudioVolume,
            pfLevel: ?*f32,
        ) callconv(WINAPI) HRESULT,
        SetMute: *const fn (
            self: *const ISimpleAudioVolume,
            bMute: BOOL,
            EventContext: ?*const Guid,
        ) callconv(WINAPI) HRESULT,
        GetMute: *const fn (
            self: *const ISimpleAudioVolume,
            pbMute: ?*BOOL,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn SetMasterVolume(self: *const T, fLevel: f32, EventContext: ?*const Guid) HRESULT {
                return @ptrCast(*const ISimpleAudioVolume.VTable, self.vtable).SetMasterVolume(@ptrCast(*const ISimpleAudioVolume, self), fLevel, EventContext);
            }
            pub inline fn GetMasterVolume(self: *const T, pfLevel: ?*f32) HRESULT {
                return @ptrCast(*const ISimpleAudioVolume.VTable, self.vtable).GetMasterVolume(@ptrCast(*const ISimpleAudioVolume, self), pfLevel);
            }
            pub inline fn SetMute(self: *const T, bMute: BOOL, EventContext: ?*const Guid) HRESULT {
                return @ptrCast(*const ISimpleAudioVolume.VTable, self.vtable).SetMute(@ptrCast(*const ISimpleAudioVolume, self), bMute, EventContext);
            }
            pub inline fn GetMute(self: *const T, pbMute: ?*BOOL) HRESULT {
                return @ptrCast(*const ISimpleAudioVolume.VTable, self.vtable).GetMute(@ptrCast(*const ISimpleAudioVolume, self), pbMute);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IPropertyStore = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetCount: *const fn (
            self: *const IPropertyStore,
            cProps: ?*u32,
        ) callconv(WINAPI) HRESULT,
        GetAt: *const fn (
            self: *const IPropertyStore,
            iProp: u32,
            pkey: ?*PROPERTYKEY,
        ) callconv(WINAPI) HRESULT,
        GetValue: *const fn (
            self: *const IPropertyStore,
            key: ?*const PROPERTYKEY,
            pv: ?*PROPVARIANT,
        ) callconv(WINAPI) HRESULT,
        SetValue: *const fn (
            self: *const IPropertyStore,
            key: ?*const PROPERTYKEY,
            propvar: ?*const PROPVARIANT,
        ) callconv(WINAPI) HRESULT,
        Commit: *const fn (
            self: *const IPropertyStore,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetCount(self: *const T, cProps: ?*u32) HRESULT {
                return @ptrCast(*const IPropertyStore.VTable, self.vtable).GetCount(@ptrCast(*const IPropertyStore, self), cProps);
            }
            pub inline fn GetAt(self: *const T, iProp: u32, pkey: ?*PROPERTYKEY) HRESULT {
                return @ptrCast(*const IPropertyStore.VTable, self.vtable).GetAt(@ptrCast(*const IPropertyStore, self), iProp, pkey);
            }
            pub inline fn GetValue(self: *const T, key: ?*const PROPERTYKEY, pv: ?*PROPVARIANT) HRESULT {
                return @ptrCast(*const IPropertyStore.VTable, self.vtable).GetValue(@ptrCast(*const IPropertyStore, self), key, pv);
            }
            pub inline fn SetValue(self: *const T, key: ?*const PROPERTYKEY, propvar: ?*const PROPVARIANT) HRESULT {
                return @ptrCast(*const IPropertyStore.VTable, self.vtable).SetValue(@ptrCast(*const IPropertyStore, self), key, propvar);
            }
            pub inline fn Commit(self: *const T) HRESULT {
                return @ptrCast(*const IPropertyStore.VTable, self.vtable).Commit(@ptrCast(*const IPropertyStore, self));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
const IID_IMMDevice = &Guid.initString("d666063f-1587-4e43-81f1-b948e807363f");
pub const IMMDevice = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Activate: *const fn (
            self: *const IMMDevice,
            iid: ?*const Guid,
            dwClsCtx: u32,
            pActivationParams: ?*PROPVARIANT,
            ppInterface: ?*?*anyopaque,
        ) callconv(WINAPI) HRESULT,
        OpenPropertyStore: *const fn (
            self: *const IMMDevice,
            stgmAccess: u32,
            ppProperties: ?*?*IPropertyStore,
        ) callconv(WINAPI) HRESULT,
        GetId: *const fn (
            self: *const IMMDevice,
            ppstrId: ?*?PWSTR,
        ) callconv(WINAPI) HRESULT,
        GetState: *const fn (
            self: *const IMMDevice,
            pdwState: ?*u32,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn Activate(self: *const T, iid: ?*const Guid, dwClsCtx: u32, pActivationParams: ?*PROPVARIANT, ppInterface: ?*?*anyopaque) HRESULT {
                return @ptrCast(*const IMMDevice.VTable, self.vtable).Activate(@ptrCast(*const IMMDevice, self), iid, dwClsCtx, pActivationParams, ppInterface);
            }
            pub inline fn OpenPropertyStore(self: *const T, stgmAccess: u32, ppProperties: ?*?*IPropertyStore) HRESULT {
                return @ptrCast(*const IMMDevice.VTable, self.vtable).OpenPropertyStore(@ptrCast(*const IMMDevice, self), stgmAccess, ppProperties);
            }
            pub inline fn GetId(self: *const T, ppstrId: ?*?PWSTR) HRESULT {
                return @ptrCast(*const IMMDevice.VTable, self.vtable).GetId(@ptrCast(*const IMMDevice, self), ppstrId);
            }
            pub inline fn GetState(self: *const T, pdwState: ?*u32) HRESULT {
                return @ptrCast(*const IMMDevice.VTable, self.vtable).GetState(@ptrCast(*const IMMDevice, self), pdwState);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_IMMNotificationClient = &Guid.initString("7991eec9-7e89-4d85-8390-6c703cec60c0");
pub const IMMNotificationClient = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        OnDeviceStateChanged: *const fn (
            self: *const IMMNotificationClient,
            pwstrDeviceId: ?[*:0]const u16,
            dwNewState: u32,
        ) callconv(WINAPI) HRESULT,
        OnDeviceAdded: *const fn (
            self: *const IMMNotificationClient,
            pwstrDeviceId: ?[*:0]const u16,
        ) callconv(WINAPI) HRESULT,
        OnDeviceRemoved: *const fn (
            self: *const IMMNotificationClient,
            pwstrDeviceId: ?[*:0]const u16,
        ) callconv(WINAPI) HRESULT,
        OnDefaultDeviceChanged: *const fn (
            self: *const IMMNotificationClient,
            flow: DataFlow,
            role: Role,
            pwstrDefaultDeviceId: ?[*:0]const u16,
        ) callconv(WINAPI) HRESULT,
        OnPropertyValueChanged: *const fn (
            self: *const IMMNotificationClient,
            pwstrDeviceId: ?[*:0]const u16,
            key: PROPERTYKEY,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn OnDeviceStateChanged(self: *const T, pwstrDeviceId: ?[*:0]const u16, dwNewState: u32) HRESULT {
                return @ptrCast(*const IMMNotificationClient.VTable, self.vtable).OnDeviceStateChanged(@ptrCast(*const IMMNotificationClient, self), pwstrDeviceId, dwNewState);
            }
            pub inline fn OnDeviceAdded(self: *const T, pwstrDeviceId: ?[*:0]const u16) HRESULT {
                return @ptrCast(*const IMMNotificationClient.VTable, self.vtable).OnDeviceAdded(@ptrCast(*const IMMNotificationClient, self), pwstrDeviceId);
            }
            pub inline fn OnDeviceRemoved(self: *const T, pwstrDeviceId: ?[*:0]const u16) HRESULT {
                return @ptrCast(*const IMMNotificationClient.VTable, self.vtable).OnDeviceRemoved(@ptrCast(*const IMMNotificationClient, self), pwstrDeviceId);
            }
            pub inline fn OnDefaultDeviceChanged(self: *const T, flow: DataFlow, role: Role, pwstrDefaultDeviceId: ?[*:0]const u16) HRESULT {
                return @ptrCast(*const IMMNotificationClient.VTable, self.vtable).OnDefaultDeviceChanged(@ptrCast(*const IMMNotificationClient, self), flow, role, pwstrDefaultDeviceId);
            }
            pub inline fn OnPropertyValueChanged(self: *const T, pwstrDeviceId: ?[*:0]const u16, key: PROPERTYKEY) HRESULT {
                return @ptrCast(*const IMMNotificationClient.VTable, self.vtable).OnPropertyValueChanged(@ptrCast(*const IMMNotificationClient, self), pwstrDeviceId, key);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_IMMDeviceCollection = &Guid.initString("0bd7a1be-7a1a-44db-8397-cc5392387b5e");
pub const IMMDeviceCollection = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetCount: *const fn (
            self: *const IMMDeviceCollection,
            pcDevices: ?*u32,
        ) callconv(WINAPI) HRESULT,
        Item: *const fn (
            self: *const IMMDeviceCollection,
            nDevice: u32,
            ppDevice: ?*?*IMMDevice,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetCount(self: *const T, pcDevices: ?*u32) HRESULT {
                return @ptrCast(*const IMMDeviceCollection.VTable, self.vtable).GetCount(@ptrCast(*const IMMDeviceCollection, self), pcDevices);
            }
            pub inline fn Item(self: *const T, nDevice: u32, ppDevice: ?*?*IMMDevice) HRESULT {
                return @ptrCast(*const IMMDeviceCollection.VTable, self.vtable).Item(@ptrCast(*const IMMDeviceCollection, self), nDevice, ppDevice);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_IMMDeviceEnumerator = &Guid.initString("a95664d2-9614-4f35-a746-de8db63617e6");
pub const IMMDeviceEnumerator = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        EnumAudioEndpoints: *const fn (
            self: *const IMMDeviceEnumerator,
            dataFlow: DataFlow,
            dwStateMask: u32,
            ppDevices: ?*?*IMMDeviceCollection,
        ) callconv(WINAPI) HRESULT,
        GetDefaultAudioEndpoint: *const fn (
            self: *const IMMDeviceEnumerator,
            dataFlow: DataFlow,
            role: Role,
            ppEndpoint: ?*?*IMMDevice,
        ) callconv(WINAPI) HRESULT,
        GetDevice: *const fn (
            self: *const IMMDeviceEnumerator,
            pwstrId: ?[*:0]const u16,
            ppDevice: ?*?*IMMDevice,
        ) callconv(WINAPI) HRESULT,
        RegisterEndpointNotificationCallback: *const fn (
            self: *const IMMDeviceEnumerator,
            pClient: ?*IMMNotificationClient,
        ) callconv(WINAPI) HRESULT,
        UnregisterEndpointNotificationCallback: *const fn (
            self: *const IMMDeviceEnumerator,
            pClient: ?*IMMNotificationClient,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn EnumAudioEndpoints(self: *const T, dataFlow: DataFlow, dwStateMask: u32, ppDevices: ?*?*IMMDeviceCollection) HRESULT {
                return @ptrCast(*const IMMDeviceEnumerator.VTable, self.vtable).EnumAudioEndpoints(@ptrCast(*const IMMDeviceEnumerator, self), dataFlow, dwStateMask, ppDevices);
            }
            pub inline fn GetDefaultAudioEndpoint(self: *const T, dataFlow: DataFlow, role: Role, ppEndpoint: ?*?*IMMDevice) HRESULT {
                return @ptrCast(*const IMMDeviceEnumerator.VTable, self.vtable).GetDefaultAudioEndpoint(@ptrCast(*const IMMDeviceEnumerator, self), dataFlow, role, ppEndpoint);
            }
            pub inline fn GetDevice(self: *const T, pwstrId: ?[*:0]const u16, ppDevice: ?*?*IMMDevice) HRESULT {
                return @ptrCast(*const IMMDeviceEnumerator.VTable, self.vtable).GetDevice(@ptrCast(*const IMMDeviceEnumerator, self), pwstrId, ppDevice);
            }
            pub inline fn RegisterEndpointNotificationCallback(self: *const T, pClient: ?*IMMNotificationClient) HRESULT {
                return @ptrCast(*const IMMDeviceEnumerator.VTable, self.vtable).RegisterEndpointNotificationCallback(@ptrCast(*const IMMDeviceEnumerator, self), pClient);
            }
            pub inline fn UnregisterEndpointNotificationCallback(self: *const T, pClient: ?*IMMNotificationClient) HRESULT {
                return @ptrCast(*const IMMDeviceEnumerator.VTable, self.vtable).UnregisterEndpointNotificationCallback(@ptrCast(*const IMMDeviceEnumerator, self), pClient);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const IID_IMMEndpoint = &Guid.initString("1be09788-6894-4089-8586-9a2a6c265ac5");
pub const IMMEndpoint = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetDataFlow: *const fn (
            self: *const IMMEndpoint,
            pDataFlow: ?*DataFlow,
        ) callconv(WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetDataFlow(self: *const T, pDataFlow: ?*DataFlow) HRESULT {
                return @ptrCast(*const IMMEndpoint.VTable, self.vtable).GetDataFlow(@ptrCast(*const IMMEndpoint, self), pDataFlow);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
pub const AUDCLNT_STREAMFLAGS_CROSSPROCESS = 65536;
pub const AUDCLNT_STREAMFLAGS_LOOPBACK = 131072;
pub const AUDCLNT_STREAMFLAGS_EVENTCALLBACK = 262144;
pub const AUDCLNT_STREAMFLAGS_NOPERSIST = 524288;
pub const AUDCLNT_STREAMFLAGS_RATEADJUST = 1048576;
pub const AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY = 134217728;
pub const AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM = 2147483648;
pub const AUDCLNT_SESSIONFLAGS_EXPIREWHENUNOWNED = 268435456;
pub const PKEY_Device_FriendlyName = PROPERTYKEY{ .fmtid = Guid.initString("a45c254e-df1c-4efd-8020-67d146a850e0"), .pid = 14 };
pub const CLSID_KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = &Guid.initString("00000003-0000-0010-8000-00aa00389b71");
pub const SPEAKER_FRONT_LEFT = 1;
pub const SPEAKER_FRONT_RIGHT = 2;
pub const SPEAKER_FRONT_CENTER = 4;
pub const SPEAKER_LOW_FREQUENCY = 8;
pub const SPEAKER_BACK_LEFT = 16;
pub const SPEAKER_BACK_RIGHT = 32;
pub const SPEAKER_FRONT_LEFT_OF_CENTER = 64;
pub const SPEAKER_FRONT_RIGHT_OF_CENTER = 128;
pub const SPEAKER_BACK_CENTER = 256;
pub const SPEAKER_SIDE_LEFT = 512;
pub const SPEAKER_SIDE_RIGHT = 1024;
pub const SPEAKER_TOP_CENTER = 2048;
pub const SPEAKER_TOP_FRONT_LEFT = 4096;
pub const SPEAKER_TOP_FRONT_CENTER = 8192;
pub const SPEAKER_TOP_FRONT_RIGHT = 16384;
pub const SPEAKER_TOP_BACK_LEFT = 32768;
pub const SPEAKER_TOP_BACK_CENTER = 65536;
pub const SPEAKER_TOP_BACK_RIGHT = 131072;
pub const SPEAKER_RESERVED = @as(u32, 2147221504);
pub const SPEAKER_ALL = @as(u32, 2147483648);
pub const CLSID_KSDATAFORMAT_SUBTYPE_PCM = &Guid.initString("00000001-0000-0010-8000-00aa00389b71");
pub const INPLACE_S_TRUNCATED = 262560;
pub const PKEY_AudioEngine_DeviceFormat = PROPERTYKEY{ .fmtid = Guid.initString("f19f064d-082c-4e27-bc73-6882a1bb8e4c"), .pid = 0 };
pub const WAVE_FORMAT_EXTENSIBLE = 65534;
pub const STGM_READ = 0;
pub const DEVICE_STATE_ACTIVE = 1;
pub const AUDCLNT_E_NOT_INITIALIZED = -2004287487;
pub const AUDCLNT_E_ALREADY_INITIALIZED = -2004287486;
pub const AUDCLNT_E_WRONG_ENDPOINT_TYPE = -2004287485;
pub const AUDCLNT_E_DEVICE_INVALIDATED = -2004287484;
pub const AUDCLNT_E_NOT_STOPPED = -2004287483;
pub const AUDCLNT_E_BUFFER_TOO_LARGE = -2004287482;
pub const AUDCLNT_E_OUT_OF_ORDER = -2004287481;
pub const AUDCLNT_E_UNSUPPORTED_FORMAT = -2004287480;
pub const AUDCLNT_E_INVALID_SIZE = -2004287479;
pub const AUDCLNT_E_DEVICE_IN_USE = -2004287478;
pub const AUDCLNT_E_BUFFER_OPERATION_PENDING = -2004287477;
pub const AUDCLNT_E_THREAD_NOT_REGISTERED = -2004287476;
pub const AUDCLNT_E_EXCLUSIVE_MODE_NOT_ALLOWED = -2004287474;
pub const AUDCLNT_E_ENDPOINT_CREATE_FAILED = -2004287473;
pub const AUDCLNT_E_SERVICE_NOT_RUNNING = -2004287472;
pub const AUDCLNT_E_EVENTHANDLE_NOT_EXPECTED = -2004287471;
pub const AUDCLNT_E_EXCLUSIVE_MODE_ONLY = -2004287470;
pub const AUDCLNT_E_BUFDURATION_PERIOD_NOT_EQUAL = -2004287469;
pub const AUDCLNT_E_EVENTHANDLE_NOT_SET = -2004287468;
pub const AUDCLNT_E_INCORRECT_BUFFER_SIZE = -2004287467;
pub const AUDCLNT_E_BUFFER_SIZE_ERROR = -2004287466;
pub const AUDCLNT_E_CPUUSAGE_EXCEEDED = -2004287465;
pub const AUDCLNT_E_BUFFER_ERROR = -2004287464;
pub const AUDCLNT_E_BUFFER_SIZE_NOT_ALIGNED = -2004287463;
pub const AUDCLNT_E_INVALID_DEVICE_PERIOD = -2004287456;
pub const AUDCLNT_E_INVALID_STREAM_FLAG = -2004287455;
pub const AUDCLNT_E_ENDPOINT_OFFLOAD_NOT_CAPABLE = -2004287454;
pub const AUDCLNT_E_OUT_OF_OFFLOAD_RESOURCES = -2004287453;
pub const AUDCLNT_E_OFFLOAD_MODE_ONLY = -2004287452;
pub const AUDCLNT_E_NONOFFLOAD_MODE_ONLY = -2004287451;
pub const AUDCLNT_E_RESOURCES_INVALIDATED = -2004287450;
pub const AUDCLNT_E_RAW_MODE_UNSUPPORTED = -2004287449;
pub const AUDCLNT_E_ENGINE_PERIODICITY_LOCKED = -2004287448;
pub const AUDCLNT_E_ENGINE_FORMAT_LOCKED = -2004287447;
pub const AUDCLNT_E_HEADTRACKING_ENABLED = -2004287440;
pub const AUDCLNT_E_HEADTRACKING_UNSUPPORTED = -2004287424;
pub const AUDCLNT_E_EFFECT_NOT_AVAILABLE = -2004287423;
pub const AUDCLNT_E_EFFECT_STATE_READ_ONLY = -2004287422;
