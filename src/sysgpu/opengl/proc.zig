const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");
const mach = @import("../../main.zig");

pub var libgl: std.DynLib = undefined;

const GlFuncPtr = *align(1) const fn () callconv(.C) void;

fn removeOptional(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .optional => |opt| opt.child,
        else => T,
    };
}

fn getProcAddress(name_ptr: [*:0]const u8) ?GlFuncPtr {
    const name = std.mem.span(name_ptr);
    return libgl.lookup(GlFuncPtr, name);
}

fn getExtProcAddress(name_ptr: [*:0]const u8) ?GlFuncPtr {
    if (builtin.target.os.tag == .linux) {
        if (glXGetProcAddress) |getProc| {
            if (getProc(name_ptr)) |ptr| return ptr;
        }
        return getProcAddress(name_ptr);
    } else {
        return @ptrCast(c.wglGetProcAddress(name_ptr));
    }
}

var glXGetProcAddress: ?*const fn ([*:0]const u8) callconv(.C) ?GlFuncPtr = null;

pub fn init() !void {
    if (builtin.target.os.tag == .linux) {
        libgl = try mach.dynLibOpen(.{ "libGL.so.1", "libGL.so" });
        glXGetProcAddress = libgl.lookup(*const fn ([*:0]const u8) callconv(.C) ?GlFuncPtr, "glXGetProcAddress");
    } else {
        libgl = try mach.dynLibOpen(.{"opengl32.dll"});
    }
}

pub fn deinit() void {
    libgl.close();
}

pub const InstanceWGL = struct {
    getExtensionsStringARB: removeOptional(c.PFNWGLGETEXTENSIONSSTRINGARBPROC),
    createContextAttribsARB: removeOptional(c.PFNWGLCREATECONTEXTATTRIBSARBPROC),
    choosePixelFormatARB: removeOptional(c.PFNWGLCHOOSEPIXELFORMATARBPROC),

    pub fn load(wgl: *InstanceWGL) void {
        wgl.getExtensionsStringARB = @ptrCast(getExtProcAddress("wglGetExtensionsStringARB"));
        wgl.createContextAttribsARB = @ptrCast(getExtProcAddress("wglCreateContextAttribsARB"));
        wgl.choosePixelFormatARB = @ptrCast(getExtProcAddress("wglChoosePixelFormatARB"));
    }
};

pub const AdapterGL = struct {
    getString: removeOptional(c.PFNGLGETSTRINGPROC),

    pub fn load(gl: *AdapterGL) void {
        gl.getString = @ptrCast(getProcAddress("glGetString"));
    }
};

pub const DeviceGL = struct {
    // 1.0
    cullFace: removeOptional(c.PFNGLCULLFACEPROC),
    frontFace: removeOptional(c.PFNGLFRONTFACEPROC),
    hint: removeOptional(c.PFNGLHINTPROC),
    lineWidth: removeOptional(c.PFNGLLINEWIDTHPROC),
    pointSize: removeOptional(c.PFNGLPOINTSIZEPROC),
    polygonMode: removeOptional(c.PFNGLPOLYGONMODEPROC),
    scissor: removeOptional(c.PFNGLSCISSORPROC),
    texParameterf: removeOptional(c.PFNGLTEXPARAMETERFPROC),
    texParameterfv: removeOptional(c.PFNGLTEXPARAMETERFVPROC),
    texParameteri: removeOptional(c.PFNGLTEXPARAMETERIPROC),
    texParameteriv: removeOptional(c.PFNGLTEXPARAMETERIVPROC),
    texImage1D: removeOptional(c.PFNGLTEXIMAGE1DPROC),
    texImage2D: removeOptional(c.PFNGLTEXIMAGE2DPROC),
    drawBuffer: removeOptional(c.PFNGLDRAWBUFFERPROC),
    clear: removeOptional(c.PFNGLCLEARPROC),
    clearColor: removeOptional(c.PFNGLCLEARCOLORPROC),
    clearStencil: removeOptional(c.PFNGLCLEARSTENCILPROC),
    clearDepth: removeOptional(c.PFNGLCLEARDEPTHPROC),
    stencilMask: removeOptional(c.PFNGLSTENCILMASKPROC),
    colorMask: removeOptional(c.PFNGLCOLORMASKPROC),
    depthMask: removeOptional(c.PFNGLDEPTHMASKPROC),
    disable: removeOptional(c.PFNGLDISABLEPROC),
    enable: removeOptional(c.PFNGLENABLEPROC),
    finish: removeOptional(c.PFNGLFINISHPROC),
    flush: removeOptional(c.PFNGLFLUSHPROC),
    blendFunc: removeOptional(c.PFNGLBLENDFUNCPROC),
    logicOp: removeOptional(c.PFNGLLOGICOPPROC),
    stencilFunc: removeOptional(c.PFNGLSTENCILFUNCPROC),
    stencilOp: removeOptional(c.PFNGLSTENCILOPPROC),
    depthFunc: removeOptional(c.PFNGLDEPTHFUNCPROC),
    pixelStoref: removeOptional(c.PFNGLPIXELSTOREFPROC),
    pixelStorei: removeOptional(c.PFNGLPIXELSTOREIPROC),
    readBuffer: removeOptional(c.PFNGLREADBUFFERPROC),
    readPixels: removeOptional(c.PFNGLREADPIXELSPROC),
    getBooleanv: removeOptional(c.PFNGLGETBOOLEANVPROC),
    getDoublev: removeOptional(c.PFNGLGETDOUBLEVPROC),
    getError: removeOptional(c.PFNGLGETERRORPROC),
    getFloatv: removeOptional(c.PFNGLGETFLOATVPROC),
    getIntegerv: removeOptional(c.PFNGLGETINTEGERVPROC),
    getString: removeOptional(c.PFNGLGETSTRINGPROC),
    getTexImage: removeOptional(c.PFNGLGETTEXIMAGEPROC),
    getTexParameterfv: removeOptional(c.PFNGLGETTEXPARAMETERFVPROC),
    getTexParameteriv: removeOptional(c.PFNGLGETTEXPARAMETERIVPROC),
    getTexLevelParameterfv: removeOptional(c.PFNGLGETTEXLEVELPARAMETERFVPROC),
    getTexLevelParameteriv: removeOptional(c.PFNGLGETTEXLEVELPARAMETERIVPROC),
    isEnabled: removeOptional(c.PFNGLISENABLEDPROC),
    depthRange: removeOptional(c.PFNGLDEPTHRANGEPROC),
    viewport: removeOptional(c.PFNGLVIEWPORTPROC),

    // 1.1
    drawArrays: removeOptional(c.PFNGLDRAWARRAYSPROC),
    drawElements: removeOptional(c.PFNGLDRAWELEMENTSPROC),
    getPointerv: removeOptional(c.PFNGLGETPOINTERVPROC),
    polygonOffset: removeOptional(c.PFNGLPOLYGONOFFSETPROC),
    copyTexImage1D: removeOptional(c.PFNGLCOPYTEXIMAGE1DPROC),
    copyTexImage2D: removeOptional(c.PFNGLCOPYTEXIMAGE2DPROC),
    copyTexSubImage1D: removeOptional(c.PFNGLCOPYTEXSUBIMAGE1DPROC),
    copyTexSubImage2D: removeOptional(c.PFNGLCOPYTEXSUBIMAGE2DPROC),
    texSubImage1D: removeOptional(c.PFNGLTEXSUBIMAGE1DPROC),
    texSubImage2D: removeOptional(c.PFNGLTEXSUBIMAGE2DPROC),
    bindTexture: removeOptional(c.PFNGLBINDTEXTUREPROC),
    deleteTextures: removeOptional(c.PFNGLDELETETEXTURESPROC),
    genTextures: removeOptional(c.PFNGLGENTEXTURESPROC),
    isTexture: removeOptional(c.PFNGLISTEXTUREPROC),

    // 1.2
    drawRangeElements: removeOptional(c.PFNGLDRAWRANGEELEMENTSPROC),
    texImage3D: removeOptional(c.PFNGLTEXIMAGE3DPROC),
    texSubImage3D: removeOptional(c.PFNGLTEXSUBIMAGE3DPROC),
    copyTexSubImage3D: removeOptional(c.PFNGLCOPYTEXSUBIMAGE3DPROC),

    // 1.3
    activeTexture: removeOptional(c.PFNGLACTIVETEXTUREPROC),
    sampleCoverage: removeOptional(c.PFNGLSAMPLECOVERAGEPROC),
    compressedTexImage3D: removeOptional(c.PFNGLCOMPRESSEDTEXIMAGE3DPROC),
    compressedTexImage2D: removeOptional(c.PFNGLCOMPRESSEDTEXIMAGE2DPROC),
    compressedTexImage1D: removeOptional(c.PFNGLCOMPRESSEDTEXIMAGE1DPROC),
    compressedTexSubImage3D: removeOptional(c.PFNGLCOMPRESSEDTEXSUBIMAGE3DPROC),
    compressedTexSubImage2D: removeOptional(c.PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC),
    compressedTexSubImage1D: removeOptional(c.PFNGLCOMPRESSEDTEXSUBIMAGE1DPROC),
    getCompressedTexImage: removeOptional(c.PFNGLGETCOMPRESSEDTEXIMAGEPROC),

    // 1.4
    blendFuncSeparate: removeOptional(c.PFNGLBLENDFUNCSEPARATEPROC),
    multiDrawArrays: removeOptional(c.PFNGLMULTIDRAWARRAYSPROC),
    multiDrawElements: removeOptional(c.PFNGLMULTIDRAWELEMENTSPROC),
    pointParameterf: removeOptional(c.PFNGLPOINTPARAMETERFPROC),
    pointParameterfv: removeOptional(c.PFNGLPOINTPARAMETERFVPROC),
    pointParameteri: removeOptional(c.PFNGLPOINTPARAMETERIPROC),
    pointParameteriv: removeOptional(c.PFNGLPOINTPARAMETERIVPROC),
    blendColor: removeOptional(c.PFNGLBLENDCOLORPROC),
    blendEquation: removeOptional(c.PFNGLBLENDEQUATIONPROC),

    // 1.5
    genQueries: removeOptional(c.PFNGLGENQUERIESPROC),
    deleteQueries: removeOptional(c.PFNGLDELETEQUERIESPROC),
    isQuery: removeOptional(c.PFNGLISQUERYPROC),
    beginQuery: removeOptional(c.PFNGLBEGINQUERYPROC),
    endQuery: removeOptional(c.PFNGLENDQUERYPROC),
    getQueryiv: removeOptional(c.PFNGLGETQUERYIVPROC),
    getQueryObjectiv: removeOptional(c.PFNGLGETQUERYOBJECTIVPROC),
    getQueryObjectuiv: removeOptional(c.PFNGLGETQUERYOBJECTUIVPROC),
    bindBuffer: removeOptional(c.PFNGLBINDBUFFERPROC),
    deleteBuffers: removeOptional(c.PFNGLDELETEBUFFERSPROC),
    genBuffers: removeOptional(c.PFNGLGENBUFFERSPROC),
    isBuffer: removeOptional(c.PFNGLISBUFFERPROC),
    bufferData: removeOptional(c.PFNGLBUFFERDATAPROC),
    bufferSubData: removeOptional(c.PFNGLBUFFERSUBDATAPROC),
    getBufferSubData: removeOptional(c.PFNGLGETBUFFERSUBDATAPROC),
    mapBuffer: removeOptional(c.PFNGLMAPBUFFERPROC),
    unmapBuffer: removeOptional(c.PFNGLUNMAPBUFFERPROC),
    getBufferParameteriv: removeOptional(c.PFNGLGETBUFFERPARAMETERIVPROC),
    getBufferPointerv: removeOptional(c.PFNGLGETBUFFERPOINTERVPROC),

    // 2.0
    blendEquationSeparate: removeOptional(c.PFNGLBLENDEQUATIONSEPARATEPROC),
    drawBuffers: removeOptional(c.PFNGLDRAWBUFFERSPROC),
    stencilOpSeparate: removeOptional(c.PFNGLSTENCILOPSEPARATEPROC),
    stencilFuncSeparate: removeOptional(c.PFNGLSTENCILFUNCSEPARATEPROC),
    stencilMaskSeparate: removeOptional(c.PFNGLSTENCILMASKSEPARATEPROC),
    attachShader: removeOptional(c.PFNGLATTACHSHADERPROC),
    bindAttribLocation: removeOptional(c.PFNGLBINDATTRIBLOCATIONPROC),
    compileShader: removeOptional(c.PFNGLCOMPILESHADERPROC),
    createProgram: removeOptional(c.PFNGLCREATEPROGRAMPROC),
    createShader: removeOptional(c.PFNGLCREATESHADERPROC),
    deleteProgram: removeOptional(c.PFNGLDELETEPROGRAMPROC),
    deleteShader: removeOptional(c.PFNGLDELETESHADERPROC),
    detachShader: removeOptional(c.PFNGLDETACHSHADERPROC),
    disableVertexAttribArray: removeOptional(c.PFNGLDISABLEVERTEXATTRIBARRAYPROC),
    enableVertexAttribArray: removeOptional(c.PFNGLENABLEVERTEXATTRIBARRAYPROC),
    getActiveAttrib: removeOptional(c.PFNGLGETACTIVEATTRIBPROC),
    getActiveUniform: removeOptional(c.PFNGLGETACTIVEUNIFORMPROC),
    getAttachedShaders: removeOptional(c.PFNGLGETATTACHEDSHADERSPROC),
    getAttribLocation: removeOptional(c.PFNGLGETATTRIBLOCATIONPROC),
    getProgramiv: removeOptional(c.PFNGLGETPROGRAMIVPROC),
    getProgramInfoLog: removeOptional(c.PFNGLGETPROGRAMINFOLOGPROC),
    getShaderiv: removeOptional(c.PFNGLGETSHADERIVPROC),
    getShaderInfoLog: removeOptional(c.PFNGLGETSHADERINFOLOGPROC),
    getShaderSource: removeOptional(c.PFNGLGETSHADERSOURCEPROC),
    getUniformLocation: removeOptional(c.PFNGLGETUNIFORMLOCATIONPROC),
    getUniformfv: removeOptional(c.PFNGLGETUNIFORMFVPROC),
    getUniformiv: removeOptional(c.PFNGLGETUNIFORMIVPROC),
    getVertexAttribdv: removeOptional(c.PFNGLGETVERTEXATTRIBDVPROC),
    getVertexAttribfv: removeOptional(c.PFNGLGETVERTEXATTRIBFVPROC),
    getVertexAttribiv: removeOptional(c.PFNGLGETVERTEXATTRIBIVPROC),
    getVertexAttribPointerv: removeOptional(c.PFNGLGETVERTEXATTRIBPOINTERVPROC),
    isProgram: removeOptional(c.PFNGLISPROGRAMPROC),
    isShader: removeOptional(c.PFNGLISSHADERPROC),
    linkProgram: removeOptional(c.PFNGLLINKPROGRAMPROC),
    shaderSource: removeOptional(c.PFNGLSHADERSOURCEPROC),
    useProgram: removeOptional(c.PFNGLUSEPROGRAMPROC),
    uniform1f: removeOptional(c.PFNGLUNIFORM1FPROC),
    uniform2f: removeOptional(c.PFNGLUNIFORM2FPROC),
    uniform3f: removeOptional(c.PFNGLUNIFORM3FPROC),
    uniform4f: removeOptional(c.PFNGLUNIFORM4FPROC),
    uniform1i: removeOptional(c.PFNGLUNIFORM1IPROC),
    uniform2i: removeOptional(c.PFNGLUNIFORM2IPROC),
    uniform3i: removeOptional(c.PFNGLUNIFORM3IPROC),
    uniform4i: removeOptional(c.PFNGLUNIFORM4IPROC),
    uniform1fv: removeOptional(c.PFNGLUNIFORM1FVPROC),
    uniform2fv: removeOptional(c.PFNGLUNIFORM2FVPROC),
    uniform3fv: removeOptional(c.PFNGLUNIFORM3FVPROC),
    uniform4fv: removeOptional(c.PFNGLUNIFORM4FVPROC),
    uniform1iv: removeOptional(c.PFNGLUNIFORM1IVPROC),
    uniform2iv: removeOptional(c.PFNGLUNIFORM2IVPROC),
    uniform3iv: removeOptional(c.PFNGLUNIFORM3IVPROC),
    uniform4iv: removeOptional(c.PFNGLUNIFORM4IVPROC),
    uniformMatrix2fv: removeOptional(c.PFNGLUNIFORMMATRIX2FVPROC),
    uniformMatrix3fv: removeOptional(c.PFNGLUNIFORMMATRIX3FVPROC),
    uniformMatrix4fv: removeOptional(c.PFNGLUNIFORMMATRIX4FVPROC),
    validateProgram: removeOptional(c.PFNGLVALIDATEPROGRAMPROC),
    vertexAttrib1d: removeOptional(c.PFNGLVERTEXATTRIB1DPROC),
    vertexAttrib1dv: removeOptional(c.PFNGLVERTEXATTRIB1DVPROC),
    vertexAttrib1f: removeOptional(c.PFNGLVERTEXATTRIB1FPROC),
    vertexAttrib1fv: removeOptional(c.PFNGLVERTEXATTRIB1FVPROC),
    vertexAttrib1s: removeOptional(c.PFNGLVERTEXATTRIB1SPROC),
    vertexAttrib1sv: removeOptional(c.PFNGLVERTEXATTRIB1SVPROC),
    vertexAttrib2d: removeOptional(c.PFNGLVERTEXATTRIB2DPROC),
    vertexAttrib2dv: removeOptional(c.PFNGLVERTEXATTRIB2DVPROC),
    vertexAttrib2f: removeOptional(c.PFNGLVERTEXATTRIB2FPROC),
    vertexAttrib2fv: removeOptional(c.PFNGLVERTEXATTRIB2FVPROC),
    vertexAttrib2s: removeOptional(c.PFNGLVERTEXATTRIB2SPROC),
    vertexAttrib2sv: removeOptional(c.PFNGLVERTEXATTRIB2SVPROC),
    vertexAttrib3d: removeOptional(c.PFNGLVERTEXATTRIB3DPROC),
    vertexAttrib3dv: removeOptional(c.PFNGLVERTEXATTRIB3DVPROC),
    vertexAttrib3f: removeOptional(c.PFNGLVERTEXATTRIB3FPROC),
    vertexAttrib3fv: removeOptional(c.PFNGLVERTEXATTRIB3FVPROC),
    vertexAttrib3s: removeOptional(c.PFNGLVERTEXATTRIB3SPROC),
    vertexAttrib3sv: removeOptional(c.PFNGLVERTEXATTRIB3SVPROC),
    vertexAttrib4Nbv: removeOptional(c.PFNGLVERTEXATTRIB4NBVPROC),
    vertexAttrib4Niv: removeOptional(c.PFNGLVERTEXATTRIB4NIVPROC),
    vertexAttrib4Nsv: removeOptional(c.PFNGLVERTEXATTRIB4NSVPROC),
    vertexAttrib4Nub: removeOptional(c.PFNGLVERTEXATTRIB4NUBPROC),
    vertexAttrib4Nubv: removeOptional(c.PFNGLVERTEXATTRIB4NUBVPROC),
    vertexAttrib4Nuiv: removeOptional(c.PFNGLVERTEXATTRIB4NUIVPROC),
    vertexAttrib4Nusv: removeOptional(c.PFNGLVERTEXATTRIB4NUSVPROC),
    vertexAttrib4bv: removeOptional(c.PFNGLVERTEXATTRIB4BVPROC),
    vertexAttrib4d: removeOptional(c.PFNGLVERTEXATTRIB4DPROC),
    vertexAttrib4dv: removeOptional(c.PFNGLVERTEXATTRIB4DVPROC),
    vertexAttrib4f: removeOptional(c.PFNGLVERTEXATTRIB4FPROC),
    vertexAttrib4fv: removeOptional(c.PFNGLVERTEXATTRIB4FVPROC),
    vertexAttrib4iv: removeOptional(c.PFNGLVERTEXATTRIB4IVPROC),
    vertexAttrib4s: removeOptional(c.PFNGLVERTEXATTRIB4SPROC),
    vertexAttrib4sv: removeOptional(c.PFNGLVERTEXATTRIB4SVPROC),
    vertexAttrib4ubv: removeOptional(c.PFNGLVERTEXATTRIB4UBVPROC),
    vertexAttrib4uiv: removeOptional(c.PFNGLVERTEXATTRIB4UIVPROC),
    vertexAttrib4usv: removeOptional(c.PFNGLVERTEXATTRIB4USVPROC),
    vertexAttribPointer: removeOptional(c.PFNGLVERTEXATTRIBPOINTERPROC),

    // 2.1
    uniformMatrix2x3fv: removeOptional(c.PFNGLUNIFORMMATRIX2X3FVPROC),
    uniformMatrix3x2fv: removeOptional(c.PFNGLUNIFORMMATRIX3X2FVPROC),
    uniformMatrix2x4fv: removeOptional(c.PFNGLUNIFORMMATRIX2X4FVPROC),
    uniformMatrix4x2fv: removeOptional(c.PFNGLUNIFORMMATRIX4X2FVPROC),
    uniformMatrix3x4fv: removeOptional(c.PFNGLUNIFORMMATRIX3X4FVPROC),
    uniformMatrix4x3fv: removeOptional(c.PFNGLUNIFORMMATRIX4X3FVPROC),

    // 3.0
    colorMaski: removeOptional(c.PFNGLCOLORMASKIPROC),
    getBooleani_v: removeOptional(c.PFNGLGETBOOLEANI_VPROC),
    getIntegeri_v: removeOptional(c.PFNGLGETINTEGERI_VPROC),
    enablei: removeOptional(c.PFNGLENABLEIPROC),
    disablei: removeOptional(c.PFNGLDISABLEIPROC),
    isEnabledi: removeOptional(c.PFNGLISENABLEDIPROC),
    beginTransformFeedback: removeOptional(c.PFNGLBEGINTRANSFORMFEEDBACKPROC),
    endTransformFeedback: removeOptional(c.PFNGLENDTRANSFORMFEEDBACKPROC),
    bindBufferRange: removeOptional(c.PFNGLBINDBUFFERRANGEPROC),
    bindBufferBase: removeOptional(c.PFNGLBINDBUFFERBASEPROC),
    transformFeedbackVaryings: removeOptional(c.PFNGLTRANSFORMFEEDBACKVARYINGSPROC),
    getTransformFeedbackVarying: removeOptional(c.PFNGLGETTRANSFORMFEEDBACKVARYINGPROC),
    clampColor: removeOptional(c.PFNGLCLAMPCOLORPROC),
    beginConditionalRender: removeOptional(c.PFNGLBEGINCONDITIONALRENDERPROC),
    endConditionalRender: removeOptional(c.PFNGLENDCONDITIONALRENDERPROC),
    vertexAttribIPointer: removeOptional(c.PFNGLVERTEXATTRIBIPOINTERPROC),
    getVertexAttribIiv: removeOptional(c.PFNGLGETVERTEXATTRIBIIVPROC),
    getVertexAttribIuiv: removeOptional(c.PFNGLGETVERTEXATTRIBIUIVPROC),
    vertexAttribI1i: removeOptional(c.PFNGLVERTEXATTRIBI1IPROC),
    vertexAttribI2i: removeOptional(c.PFNGLVERTEXATTRIBI2IPROC),
    vertexAttribI3i: removeOptional(c.PFNGLVERTEXATTRIBI3IPROC),
    vertexAttribI4i: removeOptional(c.PFNGLVERTEXATTRIBI4IPROC),
    vertexAttribI1ui: removeOptional(c.PFNGLVERTEXATTRIBI1UIPROC),
    vertexAttribI2ui: removeOptional(c.PFNGLVERTEXATTRIBI2UIPROC),
    vertexAttribI3ui: removeOptional(c.PFNGLVERTEXATTRIBI3UIPROC),
    vertexAttribI4ui: removeOptional(c.PFNGLVERTEXATTRIBI4UIPROC),
    vertexAttribI1iv: removeOptional(c.PFNGLVERTEXATTRIBI1IVPROC),
    vertexAttribI2iv: removeOptional(c.PFNGLVERTEXATTRIBI2IVPROC),
    vertexAttribI3iv: removeOptional(c.PFNGLVERTEXATTRIBI3IVPROC),
    vertexAttribI4iv: removeOptional(c.PFNGLVERTEXATTRIBI4IVPROC),
    vertexAttribI1uiv: removeOptional(c.PFNGLVERTEXATTRIBI1UIVPROC),
    vertexAttribI2uiv: removeOptional(c.PFNGLVERTEXATTRIBI2UIVPROC),
    vertexAttribI3uiv: removeOptional(c.PFNGLVERTEXATTRIBI3UIVPROC),
    vertexAttribI4uiv: removeOptional(c.PFNGLVERTEXATTRIBI4UIVPROC),
    vertexAttribI4bv: removeOptional(c.PFNGLVERTEXATTRIBI4BVPROC),
    vertexAttribI4sv: removeOptional(c.PFNGLVERTEXATTRIBI4SVPROC),
    vertexAttribI4ubv: removeOptional(c.PFNGLVERTEXATTRIBI4UBVPROC),
    vertexAttribI4usv: removeOptional(c.PFNGLVERTEXATTRIBI4USVPROC),
    getUniformuiv: removeOptional(c.PFNGLGETUNIFORMUIVPROC),
    bindFragDataLocation: removeOptional(c.PFNGLBINDFRAGDATALOCATIONPROC),
    getFragDataLocation: removeOptional(c.PFNGLGETFRAGDATALOCATIONPROC),
    uniform1ui: removeOptional(c.PFNGLUNIFORM1UIPROC),
    uniform2ui: removeOptional(c.PFNGLUNIFORM2UIPROC),
    uniform3ui: removeOptional(c.PFNGLUNIFORM3UIPROC),
    uniform4ui: removeOptional(c.PFNGLUNIFORM4UIPROC),
    uniform1uiv: removeOptional(c.PFNGLUNIFORM1UIVPROC),
    uniform2uiv: removeOptional(c.PFNGLUNIFORM2UIVPROC),
    uniform3uiv: removeOptional(c.PFNGLUNIFORM3UIVPROC),
    uniform4uiv: removeOptional(c.PFNGLUNIFORM4UIVPROC),
    texParameterIiv: removeOptional(c.PFNGLTEXPARAMETERIIVPROC),
    texParameterIuiv: removeOptional(c.PFNGLTEXPARAMETERIUIVPROC),
    getTexParameterIiv: removeOptional(c.PFNGLGETTEXPARAMETERIIVPROC),
    getTexParameterIuiv: removeOptional(c.PFNGLGETTEXPARAMETERIUIVPROC),
    clearBufferiv: removeOptional(c.PFNGLCLEARBUFFERIVPROC),
    clearBufferuiv: removeOptional(c.PFNGLCLEARBUFFERUIVPROC),
    clearBufferfv: removeOptional(c.PFNGLCLEARBUFFERFVPROC),
    clearBufferfi: removeOptional(c.PFNGLCLEARBUFFERFIPROC),
    getStringi: removeOptional(c.PFNGLGETSTRINGIPROC),
    isRenderbuffer: removeOptional(c.PFNGLISRENDERBUFFERPROC),
    bindRenderbuffer: removeOptional(c.PFNGLBINDRENDERBUFFERPROC),
    deleteRenderbuffers: removeOptional(c.PFNGLDELETERENDERBUFFERSPROC),
    genRenderbuffers: removeOptional(c.PFNGLGENRENDERBUFFERSPROC),
    renderbufferStorage: removeOptional(c.PFNGLRENDERBUFFERSTORAGEPROC),
    getRenderbufferParameteriv: removeOptional(c.PFNGLGETRENDERBUFFERPARAMETERIVPROC),
    isFramebuffer: removeOptional(c.PFNGLISFRAMEBUFFERPROC),
    bindFramebuffer: removeOptional(c.PFNGLBINDFRAMEBUFFERPROC),
    deleteFramebuffers: removeOptional(c.PFNGLDELETEFRAMEBUFFERSPROC),
    genFramebuffers: removeOptional(c.PFNGLGENFRAMEBUFFERSPROC),
    checkFramebufferStatus: removeOptional(c.PFNGLCHECKFRAMEBUFFERSTATUSPROC),
    framebufferTexture1D: removeOptional(c.PFNGLFRAMEBUFFERTEXTURE1DPROC),
    framebufferTexture2D: removeOptional(c.PFNGLFRAMEBUFFERTEXTURE2DPROC),
    framebufferTexture3D: removeOptional(c.PFNGLFRAMEBUFFERTEXTURE3DPROC),
    framebufferRenderbuffer: removeOptional(c.PFNGLFRAMEBUFFERRENDERBUFFERPROC),
    getFramebufferAttachmentParameteriv: removeOptional(c.PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC),
    generateMipmap: removeOptional(c.PFNGLGENERATEMIPMAPPROC),
    blitFramebuffer: removeOptional(c.PFNGLBLITFRAMEBUFFERPROC),
    renderbufferStorageMultisample: removeOptional(c.PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC),
    framebufferTextureLayer: removeOptional(c.PFNGLFRAMEBUFFERTEXTURELAYERPROC),
    mapBufferRange: removeOptional(c.PFNGLMAPBUFFERRANGEPROC),
    flushMappedBufferRange: removeOptional(c.PFNGLFLUSHMAPPEDBUFFERRANGEPROC),
    bindVertexArray: removeOptional(c.PFNGLBINDVERTEXARRAYPROC),
    deleteVertexArrays: removeOptional(c.PFNGLDELETEVERTEXARRAYSPROC),
    genVertexArrays: removeOptional(c.PFNGLGENVERTEXARRAYSPROC),
    isVertexArray: removeOptional(c.PFNGLISVERTEXARRAYPROC),

    // 3.1
    drawArraysInstanced: removeOptional(c.PFNGLDRAWARRAYSINSTANCEDPROC),
    drawElementsInstanced: removeOptional(c.PFNGLDRAWELEMENTSINSTANCEDPROC),
    texBuffer: removeOptional(c.PFNGLTEXBUFFERPROC),
    primitiveRestartIndex: removeOptional(c.PFNGLPRIMITIVERESTARTINDEXPROC),
    copyBufferSubData: removeOptional(c.PFNGLCOPYBUFFERSUBDATAPROC),
    getUniformIndices: removeOptional(c.PFNGLGETUNIFORMINDICESPROC),
    getActiveUniformsiv: removeOptional(c.PFNGLGETACTIVEUNIFORMSIVPROC),
    getActiveUniformName: removeOptional(c.PFNGLGETACTIVEUNIFORMNAMEPROC),
    getUniformBlockIndex: removeOptional(c.PFNGLGETUNIFORMBLOCKINDEXPROC),
    getActiveUniformBlockiv: removeOptional(c.PFNGLGETACTIVEUNIFORMBLOCKIVPROC),
    getActiveUniformBlockName: removeOptional(c.PFNGLGETACTIVEUNIFORMBLOCKNAMEPROC),
    uniformBlockBinding: removeOptional(c.PFNGLUNIFORMBLOCKBINDINGPROC),

    // 3.2
    drawElementsBaseVertex: removeOptional(c.PFNGLDRAWELEMENTSBASEVERTEXPROC),
    drawRangeElementsBaseVertex: removeOptional(c.PFNGLDRAWRANGEELEMENTSBASEVERTEXPROC),
    drawElementsInstancedBaseVertex: removeOptional(c.PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXPROC),
    multiDrawElementsBaseVertex: removeOptional(c.PFNGLMULTIDRAWELEMENTSBASEVERTEXPROC),
    provokingVertex: removeOptional(c.PFNGLPROVOKINGVERTEXPROC),
    fenceSync: removeOptional(c.PFNGLFENCESYNCPROC),
    isSync: removeOptional(c.PFNGLISSYNCPROC),
    deleteSync: removeOptional(c.PFNGLDELETESYNCPROC),
    clientWaitSync: removeOptional(c.PFNGLCLIENTWAITSYNCPROC),
    waitSync: removeOptional(c.PFNGLWAITSYNCPROC),
    getInteger64v: removeOptional(c.PFNGLGETINTEGER64VPROC),
    getSynciv: removeOptional(c.PFNGLGETSYNCIVPROC),
    getInteger64i_v: removeOptional(c.PFNGLGETINTEGER64I_VPROC),
    getBufferParameteri64v: removeOptional(c.PFNGLGETBUFFERPARAMETERI64VPROC),
    framebufferTexture: removeOptional(c.PFNGLFRAMEBUFFERTEXTUREPROC),
    texImage2DMultisample: removeOptional(c.PFNGLTEXIMAGE2DMULTISAMPLEPROC),
    texImage3DMultisample: removeOptional(c.PFNGLTEXIMAGE3DMULTISAMPLEPROC),
    getMultisamplefv: removeOptional(c.PFNGLGETMULTISAMPLEFVPROC),
    sampleMaski: removeOptional(c.PFNGLSAMPLEMASKIPROC),

    // 3.3
    bindFragDataLocationIndexed: removeOptional(c.PFNGLBINDFRAGDATALOCATIONINDEXEDPROC),
    getFragDataIndex: removeOptional(c.PFNGLGETFRAGDATAINDEXPROC),
    genSamplers: removeOptional(c.PFNGLGENSAMPLERSPROC),
    deleteSamplers: removeOptional(c.PFNGLDELETESAMPLERSPROC),
    isSampler: removeOptional(c.PFNGLISSAMPLERPROC),
    bindSampler: removeOptional(c.PFNGLBINDSAMPLERPROC),
    samplerParameteri: removeOptional(c.PFNGLSAMPLERPARAMETERIPROC),
    samplerParameteriv: removeOptional(c.PFNGLSAMPLERPARAMETERIVPROC),
    samplerParameterf: removeOptional(c.PFNGLSAMPLERPARAMETERFPROC),
    samplerParameterfv: removeOptional(c.PFNGLSAMPLERPARAMETERFVPROC),
    samplerParameterIiv: removeOptional(c.PFNGLSAMPLERPARAMETERIIVPROC),
    samplerParameterIuiv: removeOptional(c.PFNGLSAMPLERPARAMETERIUIVPROC),
    getSamplerParameteriv: removeOptional(c.PFNGLGETSAMPLERPARAMETERIVPROC),
    getSamplerParameterIiv: removeOptional(c.PFNGLGETSAMPLERPARAMETERIIVPROC),
    getSamplerParameterfv: removeOptional(c.PFNGLGETSAMPLERPARAMETERFVPROC),
    getSamplerParameterIuiv: removeOptional(c.PFNGLGETSAMPLERPARAMETERIUIVPROC),
    queryCounter: removeOptional(c.PFNGLQUERYCOUNTERPROC),
    getQueryObjecti64v: removeOptional(c.PFNGLGETQUERYOBJECTI64VPROC),
    getQueryObjectui64v: removeOptional(c.PFNGLGETQUERYOBJECTUI64VPROC),
    vertexAttribDivisor: removeOptional(c.PFNGLVERTEXATTRIBDIVISORPROC),
    vertexAttribP1ui: removeOptional(c.PFNGLVERTEXATTRIBP1UIPROC),
    vertexAttribP1uiv: removeOptional(c.PFNGLVERTEXATTRIBP1UIVPROC),
    vertexAttribP2ui: removeOptional(c.PFNGLVERTEXATTRIBP2UIPROC),
    vertexAttribP2uiv: removeOptional(c.PFNGLVERTEXATTRIBP2UIVPROC),
    vertexAttribP3ui: removeOptional(c.PFNGLVERTEXATTRIBP3UIPROC),
    vertexAttribP3uiv: removeOptional(c.PFNGLVERTEXATTRIBP3UIVPROC),
    vertexAttribP4ui: removeOptional(c.PFNGLVERTEXATTRIBP4UIPROC),
    vertexAttribP4uiv: removeOptional(c.PFNGLVERTEXATTRIBP4UIVPROC),

    // 4.0
    minSampleShading: removeOptional(c.PFNGLMINSAMPLESHADINGPROC),
    blendEquationi: removeOptional(c.PFNGLBLENDEQUATIONIPROC),
    blendEquationSeparatei: removeOptional(c.PFNGLBLENDEQUATIONSEPARATEIPROC),
    blendFunci: removeOptional(c.PFNGLBLENDFUNCIPROC),
    blendFuncSeparatei: removeOptional(c.PFNGLBLENDFUNCSEPARATEIPROC),
    drawArraysIndirect: removeOptional(c.PFNGLDRAWARRAYSINDIRECTPROC),
    drawElementsIndirect: removeOptional(c.PFNGLDRAWELEMENTSINDIRECTPROC),
    uniform1d: removeOptional(c.PFNGLUNIFORM1DPROC),
    uniform2d: removeOptional(c.PFNGLUNIFORM2DPROC),
    uniform3d: removeOptional(c.PFNGLUNIFORM3DPROC),
    uniform4d: removeOptional(c.PFNGLUNIFORM4DPROC),
    uniform1dv: removeOptional(c.PFNGLUNIFORM1DVPROC),
    uniform2dv: removeOptional(c.PFNGLUNIFORM2DVPROC),
    uniform3dv: removeOptional(c.PFNGLUNIFORM3DVPROC),
    uniform4dv: removeOptional(c.PFNGLUNIFORM4DVPROC),
    uniformMatrix2dv: removeOptional(c.PFNGLUNIFORMMATRIX2DVPROC),
    uniformMatrix3dv: removeOptional(c.PFNGLUNIFORMMATRIX3DVPROC),
    uniformMatrix4dv: removeOptional(c.PFNGLUNIFORMMATRIX4DVPROC),
    uniformMatrix2x3dv: removeOptional(c.PFNGLUNIFORMMATRIX2X3DVPROC),
    uniformMatrix2x4dv: removeOptional(c.PFNGLUNIFORMMATRIX2X4DVPROC),
    uniformMatrix3x2dv: removeOptional(c.PFNGLUNIFORMMATRIX3X2DVPROC),
    uniformMatrix3x4dv: removeOptional(c.PFNGLUNIFORMMATRIX3X4DVPROC),
    uniformMatrix4x2dv: removeOptional(c.PFNGLUNIFORMMATRIX4X2DVPROC),
    uniformMatrix4x3dv: removeOptional(c.PFNGLUNIFORMMATRIX4X3DVPROC),
    getUniformdv: removeOptional(c.PFNGLGETUNIFORMDVPROC),
    getSubroutineUniformLocation: removeOptional(c.PFNGLGETSUBROUTINEUNIFORMLOCATIONPROC),
    getSubroutineIndex: removeOptional(c.PFNGLGETSUBROUTINEINDEXPROC),
    getActiveSubroutineUniformiv: removeOptional(c.PFNGLGETACTIVESUBROUTINEUNIFORMIVPROC),
    getActiveSubroutineUniformName: removeOptional(c.PFNGLGETACTIVESUBROUTINEUNIFORMNAMEPROC),
    getActiveSubroutineName: removeOptional(c.PFNGLGETACTIVESUBROUTINENAMEPROC),
    uniformSubroutinesuiv: removeOptional(c.PFNGLUNIFORMSUBROUTINESUIVPROC),
    getUniformSubroutineuiv: removeOptional(c.PFNGLGETUNIFORMSUBROUTINEUIVPROC),
    getProgramStageiv: removeOptional(c.PFNGLGETPROGRAMSTAGEIVPROC),
    patchParameteri: removeOptional(c.PFNGLPATCHPARAMETERIPROC),
    patchParameterfv: removeOptional(c.PFNGLPATCHPARAMETERFVPROC),
    bindTransformFeedback: removeOptional(c.PFNGLBINDTRANSFORMFEEDBACKPROC),
    deleteTransformFeedbacks: removeOptional(c.PFNGLDELETETRANSFORMFEEDBACKSPROC),
    genTransformFeedbacks: removeOptional(c.PFNGLGENTRANSFORMFEEDBACKSPROC),
    isTransformFeedback: removeOptional(c.PFNGLISTRANSFORMFEEDBACKPROC),
    pauseTransformFeedback: removeOptional(c.PFNGLPAUSETRANSFORMFEEDBACKPROC),
    resumeTransformFeedback: removeOptional(c.PFNGLRESUMETRANSFORMFEEDBACKPROC),
    drawTransformFeedback: removeOptional(c.PFNGLDRAWTRANSFORMFEEDBACKPROC),
    drawTransformFeedbackStream: removeOptional(c.PFNGLDRAWTRANSFORMFEEDBACKSTREAMPROC),
    beginQueryIndexed: removeOptional(c.PFNGLBEGINQUERYINDEXEDPROC),
    endQueryIndexed: removeOptional(c.PFNGLENDQUERYINDEXEDPROC),
    getQueryIndexediv: removeOptional(c.PFNGLGETQUERYINDEXEDIVPROC),

    // 4.1
    releaseShaderCompiler: removeOptional(c.PFNGLRELEASESHADERCOMPILERPROC),
    shaderBinary: removeOptional(c.PFNGLSHADERBINARYPROC),
    getShaderPrecisionFormat: removeOptional(c.PFNGLGETSHADERPRECISIONFORMATPROC),
    depthRangef: removeOptional(c.PFNGLDEPTHRANGEFPROC),
    clearDepthf: removeOptional(c.PFNGLCLEARDEPTHFPROC),
    getProgramBinary: removeOptional(c.PFNGLGETPROGRAMBINARYPROC),
    programBinary: removeOptional(c.PFNGLPROGRAMBINARYPROC),
    programParameteri: removeOptional(c.PFNGLPROGRAMPARAMETERIPROC),
    useProgramStages: removeOptional(c.PFNGLUSEPROGRAMSTAGESPROC),
    activeShaderProgram: removeOptional(c.PFNGLACTIVESHADERPROGRAMPROC),
    createShaderProgramv: removeOptional(c.PFNGLCREATESHADERPROGRAMVPROC),
    bindProgramPipeline: removeOptional(c.PFNGLBINDPROGRAMPIPELINEPROC),
    deleteProgramPipelines: removeOptional(c.PFNGLDELETEPROGRAMPIPELINESPROC),
    genProgramPipelines: removeOptional(c.PFNGLGENPROGRAMPIPELINESPROC),
    isProgramPipeline: removeOptional(c.PFNGLISPROGRAMPIPELINEPROC),
    getProgramPipelineiv: removeOptional(c.PFNGLGETPROGRAMPIPELINEIVPROC),
    programUniform1i: removeOptional(c.PFNGLPROGRAMUNIFORM1IPROC),
    programUniform1iv: removeOptional(c.PFNGLPROGRAMUNIFORM1IVPROC),
    programUniform1f: removeOptional(c.PFNGLPROGRAMUNIFORM1FPROC),
    programUniform1fv: removeOptional(c.PFNGLPROGRAMUNIFORM1FVPROC),
    programUniform1d: removeOptional(c.PFNGLPROGRAMUNIFORM1DPROC),
    programUniform1dv: removeOptional(c.PFNGLPROGRAMUNIFORM1DVPROC),
    programUniform1ui: removeOptional(c.PFNGLPROGRAMUNIFORM1UIPROC),
    programUniform1uiv: removeOptional(c.PFNGLPROGRAMUNIFORM1UIVPROC),
    programUniform2i: removeOptional(c.PFNGLPROGRAMUNIFORM2IPROC),
    programUniform2iv: removeOptional(c.PFNGLPROGRAMUNIFORM2IVPROC),
    programUniform2f: removeOptional(c.PFNGLPROGRAMUNIFORM2FPROC),
    programUniform2fv: removeOptional(c.PFNGLPROGRAMUNIFORM2FVPROC),
    programUniform2d: removeOptional(c.PFNGLPROGRAMUNIFORM2DPROC),
    programUniform2dv: removeOptional(c.PFNGLPROGRAMUNIFORM2DVPROC),
    programUniform2ui: removeOptional(c.PFNGLPROGRAMUNIFORM2UIPROC),
    programUniform2uiv: removeOptional(c.PFNGLPROGRAMUNIFORM2UIVPROC),
    programUniform3i: removeOptional(c.PFNGLPROGRAMUNIFORM3IPROC),
    programUniform3iv: removeOptional(c.PFNGLPROGRAMUNIFORM3IVPROC),
    programUniform3f: removeOptional(c.PFNGLPROGRAMUNIFORM3FPROC),
    programUniform3fv: removeOptional(c.PFNGLPROGRAMUNIFORM3FVPROC),
    programUniform3d: removeOptional(c.PFNGLPROGRAMUNIFORM3DPROC),
    programUniform3dv: removeOptional(c.PFNGLPROGRAMUNIFORM3DVPROC),
    programUniform3ui: removeOptional(c.PFNGLPROGRAMUNIFORM3UIPROC),
    programUniform3uiv: removeOptional(c.PFNGLPROGRAMUNIFORM3UIVPROC),
    programUniform4i: removeOptional(c.PFNGLPROGRAMUNIFORM4IPROC),
    programUniform4iv: removeOptional(c.PFNGLPROGRAMUNIFORM4IVPROC),
    programUniform4f: removeOptional(c.PFNGLPROGRAMUNIFORM4FPROC),
    programUniform4fv: removeOptional(c.PFNGLPROGRAMUNIFORM4FVPROC),
    programUniform4d: removeOptional(c.PFNGLPROGRAMUNIFORM4DPROC),
    programUniform4dv: removeOptional(c.PFNGLPROGRAMUNIFORM4DVPROC),
    programUniform4ui: removeOptional(c.PFNGLPROGRAMUNIFORM4UIPROC),
    programUniform4uiv: removeOptional(c.PFNGLPROGRAMUNIFORM4UIVPROC),
    programUniformMatrix2fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2FVPROC),
    programUniformMatrix3fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3FVPROC),
    programUniformMatrix4fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4FVPROC),
    programUniformMatrix2dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2DVPROC),
    programUniformMatrix3dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3DVPROC),
    programUniformMatrix4dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4DVPROC),
    programUniformMatrix2x3fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2X3FVPROC),
    programUniformMatrix3x2fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3X2FVPROC),
    programUniformMatrix2x4fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2X4FVPROC),
    programUniformMatrix4x2fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4X2FVPROC),
    programUniformMatrix3x4fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3X4FVPROC),
    programUniformMatrix4x3fv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4X3FVPROC),
    programUniformMatrix2x3dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2X3DVPROC),
    programUniformMatrix3x2dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3X2DVPROC),
    programUniformMatrix2x4dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX2X4DVPROC),
    programUniformMatrix4x2dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4X2DVPROC),
    programUniformMatrix3x4dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX3X4DVPROC),
    programUniformMatrix4x3dv: removeOptional(c.PFNGLPROGRAMUNIFORMMATRIX4X3DVPROC),
    validateProgramPipeline: removeOptional(c.PFNGLVALIDATEPROGRAMPIPELINEPROC),
    getProgramPipelineInfoLog: removeOptional(c.PFNGLGETPROGRAMPIPELINEINFOLOGPROC),
    vertexAttribL1d: removeOptional(c.PFNGLVERTEXATTRIBL1DPROC),
    vertexAttribL2d: removeOptional(c.PFNGLVERTEXATTRIBL2DPROC),
    vertexAttribL3d: removeOptional(c.PFNGLVERTEXATTRIBL3DPROC),
    vertexAttribL4d: removeOptional(c.PFNGLVERTEXATTRIBL4DPROC),
    vertexAttribL1dv: removeOptional(c.PFNGLVERTEXATTRIBL1DVPROC),
    vertexAttribL2dv: removeOptional(c.PFNGLVERTEXATTRIBL2DVPROC),
    vertexAttribL3dv: removeOptional(c.PFNGLVERTEXATTRIBL3DVPROC),
    vertexAttribL4dv: removeOptional(c.PFNGLVERTEXATTRIBL4DVPROC),
    vertexAttribLPointer: removeOptional(c.PFNGLVERTEXATTRIBLPOINTERPROC),
    getVertexAttribLdv: removeOptional(c.PFNGLGETVERTEXATTRIBLDVPROC),
    viewportArrayv: removeOptional(c.PFNGLVIEWPORTARRAYVPROC),
    viewportIndexedf: removeOptional(c.PFNGLVIEWPORTINDEXEDFPROC),
    viewportIndexedfv: removeOptional(c.PFNGLVIEWPORTINDEXEDFVPROC),
    scissorArrayv: removeOptional(c.PFNGLSCISSORARRAYVPROC),
    scissorIndexed: removeOptional(c.PFNGLSCISSORINDEXEDPROC),
    scissorIndexedv: removeOptional(c.PFNGLSCISSORINDEXEDVPROC),
    depthRangeArrayv: removeOptional(c.PFNGLDEPTHRANGEARRAYVPROC),
    depthRangeIndexed: removeOptional(c.PFNGLDEPTHRANGEINDEXEDPROC),
    getFloati_v: removeOptional(c.PFNGLGETFLOATI_VPROC),
    getDoublei_v: removeOptional(c.PFNGLGETDOUBLEI_VPROC),

    // 4.2
    drawArraysInstancedBaseInstance: removeOptional(c.PFNGLDRAWARRAYSINSTANCEDBASEINSTANCEPROC),
    drawElementsInstancedBaseInstance: removeOptional(c.PFNGLDRAWELEMENTSINSTANCEDBASEINSTANCEPROC),
    drawElementsInstancedBaseVertexBaseInstance: removeOptional(c.PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXBASEINSTANCEPROC),
    getInternalformativ: removeOptional(c.PFNGLGETINTERNALFORMATIVPROC),
    getActiveAtomicCounterBufferiv: removeOptional(c.PFNGLGETACTIVEATOMICCOUNTERBUFFERIVPROC),
    bindImageTexture: removeOptional(c.PFNGLBINDIMAGETEXTUREPROC),
    memoryBarrier: removeOptional(c.PFNGLMEMORYBARRIERPROC),
    texStorage1D: removeOptional(c.PFNGLTEXSTORAGE1DPROC),
    texStorage2D: removeOptional(c.PFNGLTEXSTORAGE2DPROC),
    texStorage3D: removeOptional(c.PFNGLTEXSTORAGE3DPROC),
    drawTransformFeedbackInstanced: removeOptional(c.PFNGLDRAWTRANSFORMFEEDBACKINSTANCEDPROC),
    drawTransformFeedbackStreamInstanced: removeOptional(c.PFNGLDRAWTRANSFORMFEEDBACKSTREAMINSTANCEDPROC),

    // 4.3
    clearBufferData: removeOptional(c.PFNGLCLEARBUFFERDATAPROC),
    clearBufferSubData: removeOptional(c.PFNGLCLEARBUFFERSUBDATAPROC),
    dispatchCompute: removeOptional(c.PFNGLDISPATCHCOMPUTEPROC),
    dispatchComputeIndirect: removeOptional(c.PFNGLDISPATCHCOMPUTEINDIRECTPROC),
    copyImageSubData: removeOptional(c.PFNGLCOPYIMAGESUBDATAPROC),
    framebufferParameteri: removeOptional(c.PFNGLFRAMEBUFFERPARAMETERIPROC),
    getFramebufferParameteriv: removeOptional(c.PFNGLGETFRAMEBUFFERPARAMETERIVPROC),
    getInternalformati64v: removeOptional(c.PFNGLGETINTERNALFORMATI64VPROC),
    invalidateTexSubImage: removeOptional(c.PFNGLINVALIDATETEXSUBIMAGEPROC),
    invalidateTexImage: removeOptional(c.PFNGLINVALIDATETEXIMAGEPROC),
    invalidateBufferSubData: removeOptional(c.PFNGLINVALIDATEBUFFERSUBDATAPROC),
    invalidateBufferData: removeOptional(c.PFNGLINVALIDATEBUFFERDATAPROC),
    invalidateFramebuffer: removeOptional(c.PFNGLINVALIDATEFRAMEBUFFERPROC),
    invalidateSubFramebuffer: removeOptional(c.PFNGLINVALIDATESUBFRAMEBUFFERPROC),
    multiDrawArraysIndirect: removeOptional(c.PFNGLMULTIDRAWARRAYSINDIRECTPROC),
    multiDrawElementsIndirect: removeOptional(c.PFNGLMULTIDRAWELEMENTSINDIRECTPROC),
    getProgramInterfaceiv: removeOptional(c.PFNGLGETPROGRAMINTERFACEIVPROC),
    getProgramResourceIndex: removeOptional(c.PFNGLGETPROGRAMRESOURCEINDEXPROC),
    getProgramResourceName: removeOptional(c.PFNGLGETPROGRAMRESOURCENAMEPROC),
    getProgramResourceiv: removeOptional(c.PFNGLGETPROGRAMRESOURCEIVPROC),
    getProgramResourceLocation: removeOptional(c.PFNGLGETPROGRAMRESOURCELOCATIONPROC),
    getProgramResourceLocationIndex: removeOptional(c.PFNGLGETPROGRAMRESOURCELOCATIONINDEXPROC),
    shaderStorageBlockBinding: removeOptional(c.PFNGLSHADERSTORAGEBLOCKBINDINGPROC),
    texBufferRange: removeOptional(c.PFNGLTEXBUFFERRANGEPROC),
    texStorage2DMultisample: removeOptional(c.PFNGLTEXSTORAGE2DMULTISAMPLEPROC),
    texStorage3DMultisample: removeOptional(c.PFNGLTEXSTORAGE3DMULTISAMPLEPROC),
    textureView: removeOptional(c.PFNGLTEXTUREVIEWPROC),
    bindVertexBuffer: removeOptional(c.PFNGLBINDVERTEXBUFFERPROC),
    vertexAttribFormat: removeOptional(c.PFNGLVERTEXATTRIBFORMATPROC),
    vertexAttribIFormat: removeOptional(c.PFNGLVERTEXATTRIBIFORMATPROC),
    vertexAttribLFormat: removeOptional(c.PFNGLVERTEXATTRIBLFORMATPROC),
    vertexAttribBinding: removeOptional(c.PFNGLVERTEXATTRIBBINDINGPROC),
    vertexBindingDivisor: removeOptional(c.PFNGLVERTEXBINDINGDIVISORPROC),
    debugMessageControl: removeOptional(c.PFNGLDEBUGMESSAGECONTROLPROC),
    debugMessageInsert: removeOptional(c.PFNGLDEBUGMESSAGEINSERTPROC),
    debugMessageCallback: removeOptional(c.PFNGLDEBUGMESSAGECALLBACKPROC),
    getDebugMessageLog: removeOptional(c.PFNGLGETDEBUGMESSAGELOGPROC),
    pushDebugGroup: removeOptional(c.PFNGLPUSHDEBUGGROUPPROC),
    popDebugGroup: removeOptional(c.PFNGLPOPDEBUGGROUPPROC),
    objectLabel: removeOptional(c.PFNGLOBJECTLABELPROC),
    getObjectLabel: removeOptional(c.PFNGLGETOBJECTLABELPROC),
    objectPtrLabel: removeOptional(c.PFNGLOBJECTPTRLABELPROC),
    getObjectPtrLabel: removeOptional(c.PFNGLGETOBJECTPTRLABELPROC),

    // 4.4
    bufferStorage: removeOptional(c.PFNGLBUFFERSTORAGEPROC),
    clearTexImage: removeOptional(c.PFNGLCLEARTEXIMAGEPROC),
    clearTexSubImage: removeOptional(c.PFNGLCLEARTEXSUBIMAGEPROC),
    bindBuffersBase: removeOptional(c.PFNGLBINDBUFFERSBASEPROC),
    bindBuffersRange: removeOptional(c.PFNGLBINDBUFFERSRANGEPROC),
    bindTextures: removeOptional(c.PFNGLBINDTEXTURESPROC),
    bindSamplers: removeOptional(c.PFNGLBINDSAMPLERSPROC),
    bindImageTextures: removeOptional(c.PFNGLBINDIMAGETEXTURESPROC),
    bindVertexBuffers: removeOptional(c.PFNGLBINDVERTEXBUFFERSPROC),

    // 4.5
    clipControl: removeOptional(c.PFNGLCLIPCONTROLPROC),
    createTransformFeedbacks: removeOptional(c.PFNGLCREATETRANSFORMFEEDBACKSPROC),
    transformFeedbackBufferBase: removeOptional(c.PFNGLTRANSFORMFEEDBACKBUFFERBASEPROC),
    transformFeedbackBufferRange: removeOptional(c.PFNGLTRANSFORMFEEDBACKBUFFERRANGEPROC),
    getTransformFeedbackiv: removeOptional(c.PFNGLGETTRANSFORMFEEDBACKIVPROC),
    getTransformFeedbacki_v: removeOptional(c.PFNGLGETTRANSFORMFEEDBACKI_VPROC),
    getTransformFeedbacki64_v: removeOptional(c.PFNGLGETTRANSFORMFEEDBACKI64_VPROC),
    createBuffers: removeOptional(c.PFNGLCREATEBUFFERSPROC),
    namedBufferStorage: removeOptional(c.PFNGLNAMEDBUFFERSTORAGEPROC),
    namedBufferData: removeOptional(c.PFNGLNAMEDBUFFERDATAPROC),
    namedBufferSubData: removeOptional(c.PFNGLNAMEDBUFFERSUBDATAPROC),
    copyNamedBufferSubData: removeOptional(c.PFNGLCOPYNAMEDBUFFERSUBDATAPROC),
    clearNamedBufferData: removeOptional(c.PFNGLCLEARNAMEDBUFFERDATAPROC),
    clearNamedBufferSubData: removeOptional(c.PFNGLCLEARNAMEDBUFFERSUBDATAPROC),
    mapNamedBuffer: removeOptional(c.PFNGLMAPNAMEDBUFFERPROC),
    mapNamedBufferRange: removeOptional(c.PFNGLMAPNAMEDBUFFERRANGEPROC),
    unmapNamedBuffer: removeOptional(c.PFNGLUNMAPNAMEDBUFFERPROC),
    flushMappedNamedBufferRange: removeOptional(c.PFNGLFLUSHMAPPEDNAMEDBUFFERRANGEPROC),
    getNamedBufferParameteriv: removeOptional(c.PFNGLGETNAMEDBUFFERPARAMETERIVPROC),
    getNamedBufferParameteri64v: removeOptional(c.PFNGLGETNAMEDBUFFERPARAMETERI64VPROC),
    getNamedBufferPointerv: removeOptional(c.PFNGLGETNAMEDBUFFERPOINTERVPROC),
    getNamedBufferSubData: removeOptional(c.PFNGLGETNAMEDBUFFERSUBDATAPROC),
    createFramebuffers: removeOptional(c.PFNGLCREATEFRAMEBUFFERSPROC),
    namedFramebufferRenderbuffer: removeOptional(c.PFNGLNAMEDFRAMEBUFFERRENDERBUFFERPROC),
    namedFramebufferParameteri: removeOptional(c.PFNGLNAMEDFRAMEBUFFERPARAMETERIPROC),
    namedFramebufferTexture: removeOptional(c.PFNGLNAMEDFRAMEBUFFERTEXTUREPROC),
    namedFramebufferTextureLayer: removeOptional(c.PFNGLNAMEDFRAMEBUFFERTEXTURELAYERPROC),
    namedFramebufferDrawBuffer: removeOptional(c.PFNGLNAMEDFRAMEBUFFERDRAWBUFFERPROC),
    namedFramebufferDrawBuffers: removeOptional(c.PFNGLNAMEDFRAMEBUFFERDRAWBUFFERSPROC),
    namedFramebufferReadBuffer: removeOptional(c.PFNGLNAMEDFRAMEBUFFERREADBUFFERPROC),
    invalidateNamedFramebufferData: removeOptional(c.PFNGLINVALIDATENAMEDFRAMEBUFFERDATAPROC),
    invalidateNamedFramebufferSubData: removeOptional(c.PFNGLINVALIDATENAMEDFRAMEBUFFERSUBDATAPROC),
    clearNamedFramebufferiv: removeOptional(c.PFNGLCLEARNAMEDFRAMEBUFFERIVPROC),
    clearNamedFramebufferuiv: removeOptional(c.PFNGLCLEARNAMEDFRAMEBUFFERUIVPROC),
    clearNamedFramebufferfv: removeOptional(c.PFNGLCLEARNAMEDFRAMEBUFFERFVPROC),
    clearNamedFramebufferfi: removeOptional(c.PFNGLCLEARNAMEDFRAMEBUFFERFIPROC),
    blitNamedFramebuffer: removeOptional(c.PFNGLBLITNAMEDFRAMEBUFFERPROC),
    checkNamedFramebufferStatus: removeOptional(c.PFNGLCHECKNAMEDFRAMEBUFFERSTATUSPROC),
    getNamedFramebufferParameteriv: removeOptional(c.PFNGLGETNAMEDFRAMEBUFFERPARAMETERIVPROC),
    getNamedFramebufferAttachmentParameteriv: removeOptional(c.PFNGLGETNAMEDFRAMEBUFFERATTACHMENTPARAMETERIVPROC),
    createRenderbuffers: removeOptional(c.PFNGLCREATERENDERBUFFERSPROC),
    namedRenderbufferStorage: removeOptional(c.PFNGLNAMEDRENDERBUFFERSTORAGEPROC),
    namedRenderbufferStorageMultisample: removeOptional(c.PFNGLNAMEDRENDERBUFFERSTORAGEMULTISAMPLEPROC),
    getNamedRenderbufferParameteriv: removeOptional(c.PFNGLGETNAMEDRENDERBUFFERPARAMETERIVPROC),
    createTextures: removeOptional(c.PFNGLCREATETEXTURESPROC),
    textureBuffer: removeOptional(c.PFNGLTEXTUREBUFFERPROC),
    textureBufferRange: removeOptional(c.PFNGLTEXTUREBUFFERRANGEPROC),
    textureStorage1D: removeOptional(c.PFNGLTEXTURESTORAGE1DPROC),
    textureStorage2D: removeOptional(c.PFNGLTEXTURESTORAGE2DPROC),
    textureStorage3D: removeOptional(c.PFNGLTEXTURESTORAGE3DPROC),
    textureStorage2DMultisample: removeOptional(c.PFNGLTEXTURESTORAGE2DMULTISAMPLEPROC),
    textureStorage3DMultisample: removeOptional(c.PFNGLTEXTURESTORAGE3DMULTISAMPLEPROC),
    textureSubImage1D: removeOptional(c.PFNGLTEXTURESUBIMAGE1DPROC),
    textureSubImage2D: removeOptional(c.PFNGLTEXTURESUBIMAGE2DPROC),
    textureSubImage3D: removeOptional(c.PFNGLTEXTURESUBIMAGE3DPROC),
    compressedTextureSubImage1D: removeOptional(c.PFNGLCOMPRESSEDTEXTURESUBIMAGE1DPROC),
    compressedTextureSubImage2D: removeOptional(c.PFNGLCOMPRESSEDTEXTURESUBIMAGE2DPROC),
    compressedTextureSubImage3D: removeOptional(c.PFNGLCOMPRESSEDTEXTURESUBIMAGE3DPROC),
    copyTextureSubImage1D: removeOptional(c.PFNGLCOPYTEXTURESUBIMAGE1DPROC),
    copyTextureSubImage2D: removeOptional(c.PFNGLCOPYTEXTURESUBIMAGE2DPROC),
    copyTextureSubImage3D: removeOptional(c.PFNGLCOPYTEXTURESUBIMAGE3DPROC),
    textureParameterf: removeOptional(c.PFNGLTEXTUREPARAMETERFPROC),
    textureParameterfv: removeOptional(c.PFNGLTEXTUREPARAMETERFVPROC),
    textureParameteri: removeOptional(c.PFNGLTEXTUREPARAMETERIPROC),
    textureParameterIiv: removeOptional(c.PFNGLTEXTUREPARAMETERIIVPROC),
    textureParameterIuiv: removeOptional(c.PFNGLTEXTUREPARAMETERIUIVPROC),
    textureParameteriv: removeOptional(c.PFNGLTEXTUREPARAMETERIVPROC),
    generateTextureMipmap: removeOptional(c.PFNGLGENERATETEXTUREMIPMAPPROC),
    bindTextureUnit: removeOptional(c.PFNGLBINDTEXTUREUNITPROC),
    getTextureImage: removeOptional(c.PFNGLGETTEXTUREIMAGEPROC),
    getCompressedTextureImage: removeOptional(c.PFNGLGETCOMPRESSEDTEXTUREIMAGEPROC),
    getTextureLevelParameterfv: removeOptional(c.PFNGLGETTEXTURELEVELPARAMETERFVPROC),
    getTextureLevelParameteriv: removeOptional(c.PFNGLGETTEXTURELEVELPARAMETERIVPROC),
    getTextureParameterfv: removeOptional(c.PFNGLGETTEXTUREPARAMETERFVPROC),
    getTextureParameterIiv: removeOptional(c.PFNGLGETTEXTUREPARAMETERIIVPROC),
    getTextureParameterIuiv: removeOptional(c.PFNGLGETTEXTUREPARAMETERIUIVPROC),
    getTextureParameteriv: removeOptional(c.PFNGLGETTEXTUREPARAMETERIVPROC),
    createVertexArrays: removeOptional(c.PFNGLCREATEVERTEXARRAYSPROC),
    disableVertexArrayAttrib: removeOptional(c.PFNGLDISABLEVERTEXARRAYATTRIBPROC),
    enableVertexArrayAttrib: removeOptional(c.PFNGLENABLEVERTEXARRAYATTRIBPROC),
    vertexArrayElementBuffer: removeOptional(c.PFNGLVERTEXARRAYELEMENTBUFFERPROC),
    vertexArrayVertexBuffer: removeOptional(c.PFNGLVERTEXARRAYVERTEXBUFFERPROC),
    vertexArrayVertexBuffers: removeOptional(c.PFNGLVERTEXARRAYVERTEXBUFFERSPROC),
    vertexArrayAttribBinding: removeOptional(c.PFNGLVERTEXARRAYATTRIBBINDINGPROC),
    vertexArrayAttribFormat: removeOptional(c.PFNGLVERTEXARRAYATTRIBFORMATPROC),
    vertexArrayAttribIFormat: removeOptional(c.PFNGLVERTEXARRAYATTRIBIFORMATPROC),
    vertexArrayAttribLFormat: removeOptional(c.PFNGLVERTEXARRAYATTRIBLFORMATPROC),
    vertexArrayBindingDivisor: removeOptional(c.PFNGLVERTEXARRAYBINDINGDIVISORPROC),
    getVertexArrayiv: removeOptional(c.PFNGLGETVERTEXARRAYIVPROC),
    getVertexArrayIndexediv: removeOptional(c.PFNGLGETVERTEXARRAYINDEXEDIVPROC),
    getVertexArrayIndexed64iv: removeOptional(c.PFNGLGETVERTEXARRAYINDEXED64IVPROC),
    createSamplers: removeOptional(c.PFNGLCREATESAMPLERSPROC),
    createProgramPipelines: removeOptional(c.PFNGLCREATEPROGRAMPIPELINESPROC),
    createQueries: removeOptional(c.PFNGLCREATEQUERIESPROC),
    getQueryBufferObjecti64v: removeOptional(c.PFNGLGETQUERYBUFFEROBJECTI64VPROC),
    getQueryBufferObjectiv: removeOptional(c.PFNGLGETQUERYBUFFEROBJECTIVPROC),
    getQueryBufferObjectui64v: removeOptional(c.PFNGLGETQUERYBUFFEROBJECTUI64VPROC),
    getQueryBufferObjectuiv: removeOptional(c.PFNGLGETQUERYBUFFEROBJECTUIVPROC),
    memoryBarrierByRegion: removeOptional(c.PFNGLMEMORYBARRIERBYREGIONPROC),
    getTextureSubImage: removeOptional(c.PFNGLGETTEXTURESUBIMAGEPROC),
    getCompressedTextureSubImage: removeOptional(c.PFNGLGETCOMPRESSEDTEXTURESUBIMAGEPROC),
    getGraphicsResetStatus: removeOptional(c.PFNGLGETGRAPHICSRESETSTATUSPROC),
    getnCompressedTexImage: removeOptional(c.PFNGLGETNCOMPRESSEDTEXIMAGEPROC),
    getnTexImage: removeOptional(c.PFNGLGETNTEXIMAGEPROC),
    getnUniformdv: removeOptional(c.PFNGLGETNUNIFORMDVPROC),
    getnUniformfv: removeOptional(c.PFNGLGETNUNIFORMFVPROC),
    getnUniformiv: removeOptional(c.PFNGLGETNUNIFORMIVPROC),
    getnUniformuiv: removeOptional(c.PFNGLGETNUNIFORMUIVPROC),
    readnPixels: removeOptional(c.PFNGLREADNPIXELSPROC),
    textureBarrier: removeOptional(c.PFNGLTEXTUREBARRIERPROC),

    // 4.6
    specializeShader: removeOptional(c.PFNGLSPECIALIZESHADERPROC),
    multiDrawArraysIndirectCount: removeOptional(c.PFNGLMULTIDRAWARRAYSINDIRECTCOUNTPROC),
    multiDrawElementsIndirectCount: removeOptional(c.PFNGLMULTIDRAWELEMENTSINDIRECTCOUNTPROC),
    polygonOffsetClamp: removeOptional(c.PFNGLPOLYGONOFFSETCLAMPPROC),

    pub fn loadVersion(gl: *DeviceGL, major_version: u32, minor_version: u32) void {
        const version = major_version * 100 + minor_version * 10;

        if (version >= 100) {
            gl.cullFace = @ptrCast(getProcAddress("glCullFace"));
            gl.frontFace = @ptrCast(getProcAddress("glFrontFace"));
            gl.hint = @ptrCast(getProcAddress("glHint"));
            gl.lineWidth = @ptrCast(getProcAddress("glLineWidth"));
            gl.pointSize = @ptrCast(getProcAddress("glPointSize"));
            gl.polygonMode = @ptrCast(getProcAddress("glPolygonMode"));
            gl.scissor = @ptrCast(getProcAddress("glScissor"));
            gl.texParameterf = @ptrCast(getProcAddress("glTexParameterf"));
            gl.texParameterfv = @ptrCast(getProcAddress("glTexParameterfv"));
            gl.texParameteri = @ptrCast(getProcAddress("glTexParameteri"));
            gl.texParameteriv = @ptrCast(getProcAddress("glTexParameteriv"));
            gl.texImage1D = @ptrCast(getProcAddress("glTexImage1D"));
            gl.texImage2D = @ptrCast(getProcAddress("glTexImage2D"));
            gl.drawBuffer = @ptrCast(getProcAddress("glDrawBuffer"));
            gl.clear = @ptrCast(getProcAddress("glClear"));
            gl.clearColor = @ptrCast(getProcAddress("glClearColor"));
            gl.clearStencil = @ptrCast(getProcAddress("glClearStencil"));
            gl.clearDepth = @ptrCast(getProcAddress("glClearDepth"));
            gl.stencilMask = @ptrCast(getProcAddress("glStencilMask"));
            gl.colorMask = @ptrCast(getProcAddress("glColorMask"));
            gl.depthMask = @ptrCast(getProcAddress("glDepthMask"));
            gl.disable = @ptrCast(getProcAddress("glDisable"));
            gl.enable = @ptrCast(getProcAddress("glEnable"));
            gl.finish = @ptrCast(getProcAddress("glFinish"));
            gl.flush = @ptrCast(getProcAddress("glFlush"));
            gl.blendFunc = @ptrCast(getProcAddress("glBlendFunc"));
            gl.logicOp = @ptrCast(getProcAddress("glLogicOp"));
            gl.stencilFunc = @ptrCast(getProcAddress("glStencilFunc"));
            gl.stencilOp = @ptrCast(getProcAddress("glStencilOp"));
            gl.depthFunc = @ptrCast(getProcAddress("glDepthFunc"));
            gl.pixelStoref = @ptrCast(getProcAddress("glPixelStoref"));
            gl.pixelStorei = @ptrCast(getProcAddress("glPixelStorei"));
            gl.readBuffer = @ptrCast(getProcAddress("glReadBuffer"));
            gl.readPixels = @ptrCast(getProcAddress("glReadPixels"));
            gl.getBooleanv = @ptrCast(getProcAddress("glGetBooleanv"));
            gl.getDoublev = @ptrCast(getProcAddress("glGetDoublev"));
            gl.getError = @ptrCast(getProcAddress("glGetError"));
            gl.getFloatv = @ptrCast(getProcAddress("glGetFloatv"));
            gl.getIntegerv = @ptrCast(getProcAddress("glGetIntegerv"));
            gl.getString = @ptrCast(getProcAddress("glGetString"));
            gl.getTexImage = @ptrCast(getProcAddress("glGetTexImage"));
            gl.getTexParameterfv = @ptrCast(getProcAddress("glGetTexParameterfv"));
            gl.getTexParameteriv = @ptrCast(getProcAddress("glGetTexParameteriv"));
            gl.getTexLevelParameterfv = @ptrCast(getProcAddress("glGetTexLevelParameterfv"));
            gl.getTexLevelParameteriv = @ptrCast(getProcAddress("glGetTexLevelParameteriv"));
            gl.isEnabled = @ptrCast(getProcAddress("glIsEnabled"));
            gl.depthRange = @ptrCast(getProcAddress("glDepthRange"));
            gl.viewport = @ptrCast(getProcAddress("glViewport"));
        }

        if (version >= 110) {
            gl.drawArrays = @ptrCast(getProcAddress("glDrawArrays"));
            gl.drawElements = @ptrCast(getProcAddress("glDrawElements"));
            gl.getPointerv = @ptrCast(getProcAddress("glGetPointerv"));
            gl.polygonOffset = @ptrCast(getProcAddress("glPolygonOffset"));
            gl.copyTexImage1D = @ptrCast(getProcAddress("glCopyTexImage1D"));
            gl.copyTexImage2D = @ptrCast(getProcAddress("glCopyTexImage2D"));
            gl.copyTexSubImage1D = @ptrCast(getProcAddress("glCopyTexSubImage1D"));
            gl.copyTexSubImage2D = @ptrCast(getProcAddress("glCopyTexSubImage2D"));
            gl.texSubImage1D = @ptrCast(getProcAddress("glTexSubImage1D"));
            gl.texSubImage2D = @ptrCast(getProcAddress("glTexSubImage2D"));
            gl.bindTexture = @ptrCast(getProcAddress("glBindTexture"));
            gl.deleteTextures = @ptrCast(getProcAddress("glDeleteTextures"));
            gl.genTextures = @ptrCast(getProcAddress("glGenTextures"));
            gl.isTexture = @ptrCast(getProcAddress("glIsTexture"));
        }

        if (version >= 120) {
            gl.drawRangeElements = @ptrCast(getExtProcAddress("glDrawRangeElements"));
            gl.texImage3D = @ptrCast(getExtProcAddress("glTexImage3D"));
            gl.texSubImage3D = @ptrCast(getExtProcAddress("glTexSubImage3D"));
            gl.copyTexSubImage3D = @ptrCast(getExtProcAddress("glCopyTexSubImage3D"));
        }

        if (version >= 130) {
            gl.activeTexture = @ptrCast(getExtProcAddress("glActiveTexture"));
            gl.sampleCoverage = @ptrCast(getExtProcAddress("glSampleCoverage"));
            gl.compressedTexImage3D = @ptrCast(getExtProcAddress("glCompressedTexImage3D"));
            gl.compressedTexImage2D = @ptrCast(getExtProcAddress("glCompressedTexImage2D"));
            gl.compressedTexImage1D = @ptrCast(getExtProcAddress("glCompressedTexImage1D"));
            gl.compressedTexSubImage3D = @ptrCast(getExtProcAddress("glCompressedTexSubImage3D"));
            gl.compressedTexSubImage2D = @ptrCast(getExtProcAddress("glCompressedTexSubImage2D"));
            gl.compressedTexSubImage1D = @ptrCast(getExtProcAddress("glCompressedTexSubImage1D"));
            gl.getCompressedTexImage = @ptrCast(getExtProcAddress("glGetCompressedTexImage"));
        }

        if (version >= 140) {
            gl.blendFuncSeparate = @ptrCast(getExtProcAddress("glBlendFuncSeparate"));
            gl.multiDrawArrays = @ptrCast(getExtProcAddress("glMultiDrawArrays"));
            gl.multiDrawElements = @ptrCast(getExtProcAddress("glMultiDrawElements"));
            gl.pointParameterf = @ptrCast(getExtProcAddress("glPointParameterf"));
            gl.pointParameterfv = @ptrCast(getExtProcAddress("glPointParameterfv"));
            gl.pointParameteri = @ptrCast(getExtProcAddress("glPointParameteri"));
            gl.pointParameteriv = @ptrCast(getExtProcAddress("glPointParameteriv"));
            gl.blendColor = @ptrCast(getExtProcAddress("glBlendColor"));
            gl.blendEquation = @ptrCast(getExtProcAddress("glBlendEquation"));
        }

        if (version >= 150) {
            gl.genQueries = @ptrCast(getExtProcAddress("glGenQueries"));
            gl.deleteQueries = @ptrCast(getExtProcAddress("glDeleteQueries"));
            gl.isQuery = @ptrCast(getExtProcAddress("glIsQuery"));
            gl.beginQuery = @ptrCast(getExtProcAddress("glBeginQuery"));
            gl.endQuery = @ptrCast(getExtProcAddress("glEndQuery"));
            gl.getQueryiv = @ptrCast(getExtProcAddress("glGetQueryiv"));
            gl.getQueryObjectiv = @ptrCast(getExtProcAddress("glGetQueryObjectiv"));
            gl.getQueryObjectuiv = @ptrCast(getExtProcAddress("glGetQueryObjectuiv"));
            gl.bindBuffer = @ptrCast(getExtProcAddress("glBindBuffer"));
            gl.deleteBuffers = @ptrCast(getExtProcAddress("glDeleteBuffers"));
            gl.genBuffers = @ptrCast(getExtProcAddress("glGenBuffers"));
            gl.isBuffer = @ptrCast(getExtProcAddress("glIsBuffer"));
            gl.bufferData = @ptrCast(getExtProcAddress("glBufferData"));
            gl.bufferSubData = @ptrCast(getExtProcAddress("glBufferSubData"));
            gl.getBufferSubData = @ptrCast(getExtProcAddress("glGetBufferSubData"));
            gl.mapBuffer = @ptrCast(getExtProcAddress("glMapBuffer"));
            gl.unmapBuffer = @ptrCast(getExtProcAddress("glUnmapBuffer"));
            gl.getBufferParameteriv = @ptrCast(getExtProcAddress("glGetBufferParameteriv"));
            gl.getBufferPointerv = @ptrCast(getExtProcAddress("glGetBufferPointerv"));
        }

        if (version >= 200) {
            gl.blendEquationSeparate = @ptrCast(getExtProcAddress("glBlendEquationSeparate"));
            gl.drawBuffers = @ptrCast(getExtProcAddress("glDrawBuffers"));
            gl.stencilOpSeparate = @ptrCast(getExtProcAddress("glStencilOpSeparate"));
            gl.stencilFuncSeparate = @ptrCast(getExtProcAddress("glStencilFuncSeparate"));
            gl.stencilMaskSeparate = @ptrCast(getExtProcAddress("glStencilMaskSeparate"));
            gl.attachShader = @ptrCast(getExtProcAddress("glAttachShader"));
            gl.bindAttribLocation = @ptrCast(getExtProcAddress("glBindAttribLocation"));
            gl.compileShader = @ptrCast(getExtProcAddress("glCompileShader"));
            gl.createProgram = @ptrCast(getExtProcAddress("glCreateProgram"));
            gl.createShader = @ptrCast(getExtProcAddress("glCreateShader"));
            gl.deleteProgram = @ptrCast(getExtProcAddress("glDeleteProgram"));
            gl.deleteShader = @ptrCast(getExtProcAddress("glDeleteShader"));
            gl.detachShader = @ptrCast(getExtProcAddress("glDetachShader"));
            gl.disableVertexAttribArray = @ptrCast(getExtProcAddress("glDisableVertexAttribArray"));
            gl.enableVertexAttribArray = @ptrCast(getExtProcAddress("glEnableVertexAttribArray"));
            gl.getActiveAttrib = @ptrCast(getExtProcAddress("glGetActiveAttrib"));
            gl.getActiveUniform = @ptrCast(getExtProcAddress("glGetActiveUniform"));
            gl.getAttachedShaders = @ptrCast(getExtProcAddress("glGetAttachedShaders"));
            gl.getAttribLocation = @ptrCast(getExtProcAddress("glGetAttribLocation"));
            gl.getProgramiv = @ptrCast(getExtProcAddress("glGetProgramiv"));
            gl.getProgramInfoLog = @ptrCast(getExtProcAddress("glGetProgramInfoLog"));
            gl.getShaderiv = @ptrCast(getExtProcAddress("glGetShaderiv"));
            gl.getShaderInfoLog = @ptrCast(getExtProcAddress("glGetShaderInfoLog"));
            gl.getShaderSource = @ptrCast(getExtProcAddress("glGetShaderSource"));
            gl.getUniformLocation = @ptrCast(getExtProcAddress("glGetUniformLocation"));
            gl.getUniformfv = @ptrCast(getExtProcAddress("glGetUniformfv"));
            gl.getUniformiv = @ptrCast(getExtProcAddress("glGetUniformiv"));
            gl.getVertexAttribdv = @ptrCast(getExtProcAddress("glGetVertexAttribdv"));
            gl.getVertexAttribfv = @ptrCast(getExtProcAddress("glGetVertexAttribfv"));
            gl.getVertexAttribiv = @ptrCast(getExtProcAddress("glGetVertexAttribiv"));
            gl.getVertexAttribPointerv = @ptrCast(getExtProcAddress("glGetVertexAttribPointerv"));
            gl.isProgram = @ptrCast(getExtProcAddress("glIsProgram"));
            gl.isShader = @ptrCast(getExtProcAddress("glIsShader"));
            gl.linkProgram = @ptrCast(getExtProcAddress("glLinkProgram"));
            gl.shaderSource = @ptrCast(getExtProcAddress("glShaderSource"));
            gl.useProgram = @ptrCast(getExtProcAddress("glUseProgram"));
            gl.uniform1f = @ptrCast(getExtProcAddress("glUniform1f"));
            gl.uniform2f = @ptrCast(getExtProcAddress("glUniform2f"));
            gl.uniform3f = @ptrCast(getExtProcAddress("glUniform3f"));
            gl.uniform4f = @ptrCast(getExtProcAddress("glUniform4f"));
            gl.uniform1i = @ptrCast(getExtProcAddress("glUniform1i"));
            gl.uniform2i = @ptrCast(getExtProcAddress("glUniform2i"));
            gl.uniform3i = @ptrCast(getExtProcAddress("glUniform3i"));
            gl.uniform4i = @ptrCast(getExtProcAddress("glUniform4i"));
            gl.uniform1fv = @ptrCast(getExtProcAddress("glUniform1fv"));
            gl.uniform2fv = @ptrCast(getExtProcAddress("glUniform2fv"));
            gl.uniform3fv = @ptrCast(getExtProcAddress("glUniform3fv"));
            gl.uniform4fv = @ptrCast(getExtProcAddress("glUniform4fv"));
            gl.uniform1iv = @ptrCast(getExtProcAddress("glUniform1iv"));
            gl.uniform2iv = @ptrCast(getExtProcAddress("glUniform2iv"));
            gl.uniform3iv = @ptrCast(getExtProcAddress("glUniform3iv"));
            gl.uniform4iv = @ptrCast(getExtProcAddress("glUniform4iv"));
            gl.uniformMatrix2fv = @ptrCast(getExtProcAddress("glUniformMatrix2fv"));
            gl.uniformMatrix3fv = @ptrCast(getExtProcAddress("glUniformMatrix3fv"));
            gl.uniformMatrix4fv = @ptrCast(getExtProcAddress("glUniformMatrix4fv"));
            gl.validateProgram = @ptrCast(getExtProcAddress("glValidateProgram"));
            gl.vertexAttrib1d = @ptrCast(getExtProcAddress("glVertexAttrib1d"));
            gl.vertexAttrib1dv = @ptrCast(getExtProcAddress("glVertexAttrib1dv"));
            gl.vertexAttrib1f = @ptrCast(getExtProcAddress("glVertexAttrib1f"));
            gl.vertexAttrib1fv = @ptrCast(getExtProcAddress("glVertexAttrib1fv"));
            gl.vertexAttrib1s = @ptrCast(getExtProcAddress("glVertexAttrib1s"));
            gl.vertexAttrib1sv = @ptrCast(getExtProcAddress("glVertexAttrib1sv"));
            gl.vertexAttrib2d = @ptrCast(getExtProcAddress("glVertexAttrib2d"));
            gl.vertexAttrib2dv = @ptrCast(getExtProcAddress("glVertexAttrib2dv"));
            gl.vertexAttrib2f = @ptrCast(getExtProcAddress("glVertexAttrib2f"));
            gl.vertexAttrib2fv = @ptrCast(getExtProcAddress("glVertexAttrib2fv"));
            gl.vertexAttrib2s = @ptrCast(getExtProcAddress("glVertexAttrib2s"));
            gl.vertexAttrib2sv = @ptrCast(getExtProcAddress("glVertexAttrib2sv"));
            gl.vertexAttrib3d = @ptrCast(getExtProcAddress("glVertexAttrib3d"));
            gl.vertexAttrib3dv = @ptrCast(getExtProcAddress("glVertexAttrib3dv"));
            gl.vertexAttrib3f = @ptrCast(getExtProcAddress("glVertexAttrib3f"));
            gl.vertexAttrib3fv = @ptrCast(getExtProcAddress("glVertexAttrib3fv"));
            gl.vertexAttrib3s = @ptrCast(getExtProcAddress("glVertexAttrib3s"));
            gl.vertexAttrib3sv = @ptrCast(getExtProcAddress("glVertexAttrib3sv"));
            gl.vertexAttrib4Nbv = @ptrCast(getExtProcAddress("glVertexAttrib4Nbv"));
            gl.vertexAttrib4Niv = @ptrCast(getExtProcAddress("glVertexAttrib4Niv"));
            gl.vertexAttrib4Nsv = @ptrCast(getExtProcAddress("glVertexAttrib4Nsv"));
            gl.vertexAttrib4Nub = @ptrCast(getExtProcAddress("glVertexAttrib4Nub"));
            gl.vertexAttrib4Nubv = @ptrCast(getExtProcAddress("glVertexAttrib4Nubv"));
            gl.vertexAttrib4Nuiv = @ptrCast(getExtProcAddress("glVertexAttrib4Nuiv"));
            gl.vertexAttrib4Nusv = @ptrCast(getExtProcAddress("glVertexAttrib4Nusv"));
            gl.vertexAttrib4bv = @ptrCast(getExtProcAddress("glVertexAttrib4bv"));
            gl.vertexAttrib4d = @ptrCast(getExtProcAddress("glVertexAttrib4d"));
            gl.vertexAttrib4dv = @ptrCast(getExtProcAddress("glVertexAttrib4dv"));
            gl.vertexAttrib4f = @ptrCast(getExtProcAddress("glVertexAttrib4f"));
            gl.vertexAttrib4fv = @ptrCast(getExtProcAddress("glVertexAttrib4fv"));
            gl.vertexAttrib4iv = @ptrCast(getExtProcAddress("glVertexAttrib4iv"));
            gl.vertexAttrib4s = @ptrCast(getExtProcAddress("glVertexAttrib4s"));
            gl.vertexAttrib4sv = @ptrCast(getExtProcAddress("glVertexAttrib4sv"));
            gl.vertexAttrib4ubv = @ptrCast(getExtProcAddress("glVertexAttrib4ubv"));
            gl.vertexAttrib4uiv = @ptrCast(getExtProcAddress("glVertexAttrib4uiv"));
            gl.vertexAttrib4usv = @ptrCast(getExtProcAddress("glVertexAttrib4usv"));
            gl.vertexAttribPointer = @ptrCast(getExtProcAddress("glVertexAttribPointer"));
        }

        if (version >= 210) {
            gl.uniformMatrix2x3fv = @ptrCast(getExtProcAddress("glUniformMatrix2x3fv"));
            gl.uniformMatrix3x2fv = @ptrCast(getExtProcAddress("glUniformMatrix3x2fv"));
            gl.uniformMatrix2x4fv = @ptrCast(getExtProcAddress("glUniformMatrix2x4fv"));
            gl.uniformMatrix4x2fv = @ptrCast(getExtProcAddress("glUniformMatrix4x2fv"));
            gl.uniformMatrix3x4fv = @ptrCast(getExtProcAddress("glUniformMatrix3x4fv"));
            gl.uniformMatrix4x3fv = @ptrCast(getExtProcAddress("glUniformMatrix4x3fv"));
        }

        if (version >= 300) {
            gl.colorMaski = @ptrCast(getExtProcAddress("glColorMaski"));
            gl.getBooleani_v = @ptrCast(getExtProcAddress("glGetBooleani_v"));
            gl.getIntegeri_v = @ptrCast(getExtProcAddress("glGetIntegeri_v"));
            gl.enablei = @ptrCast(getExtProcAddress("glEnablei"));
            gl.disablei = @ptrCast(getExtProcAddress("glDisablei"));
            gl.isEnabledi = @ptrCast(getExtProcAddress("glIsEnabledi"));
            gl.beginTransformFeedback = @ptrCast(getExtProcAddress("glBeginTransformFeedback"));
            gl.endTransformFeedback = @ptrCast(getExtProcAddress("glEndTransformFeedback"));
            gl.bindBufferRange = @ptrCast(getExtProcAddress("glBindBufferRange"));
            gl.bindBufferBase = @ptrCast(getExtProcAddress("glBindBufferBase"));
            gl.transformFeedbackVaryings = @ptrCast(getExtProcAddress("glTransformFeedbackVaryings"));
            gl.getTransformFeedbackVarying = @ptrCast(getExtProcAddress("glGetTransformFeedbackVarying"));
            gl.clampColor = @ptrCast(getExtProcAddress("glClampColor"));
            gl.beginConditionalRender = @ptrCast(getExtProcAddress("glBeginConditionalRender"));
            gl.endConditionalRender = @ptrCast(getExtProcAddress("glEndConditionalRender"));
            gl.vertexAttribIPointer = @ptrCast(getExtProcAddress("glVertexAttribIPointer"));
            gl.getVertexAttribIiv = @ptrCast(getExtProcAddress("glGetVertexAttribIiv"));
            gl.getVertexAttribIuiv = @ptrCast(getExtProcAddress("glGetVertexAttribIuiv"));
            gl.vertexAttribI1i = @ptrCast(getExtProcAddress("glVertexAttribI1i"));
            gl.vertexAttribI2i = @ptrCast(getExtProcAddress("glVertexAttribI2i"));
            gl.vertexAttribI3i = @ptrCast(getExtProcAddress("glVertexAttribI3i"));
            gl.vertexAttribI4i = @ptrCast(getExtProcAddress("glVertexAttribI4i"));
            gl.vertexAttribI1ui = @ptrCast(getExtProcAddress("glVertexAttribI1ui"));
            gl.vertexAttribI2ui = @ptrCast(getExtProcAddress("glVertexAttribI2ui"));
            gl.vertexAttribI3ui = @ptrCast(getExtProcAddress("glVertexAttribI3ui"));
            gl.vertexAttribI4ui = @ptrCast(getExtProcAddress("glVertexAttribI4ui"));
            gl.vertexAttribI1iv = @ptrCast(getExtProcAddress("glVertexAttribI1iv"));
            gl.vertexAttribI2iv = @ptrCast(getExtProcAddress("glVertexAttribI2iv"));
            gl.vertexAttribI3iv = @ptrCast(getExtProcAddress("glVertexAttribI3iv"));
            gl.vertexAttribI4iv = @ptrCast(getExtProcAddress("glVertexAttribI4iv"));
            gl.vertexAttribI1uiv = @ptrCast(getExtProcAddress("glVertexAttribI1uiv"));
            gl.vertexAttribI2uiv = @ptrCast(getExtProcAddress("glVertexAttribI2uiv"));
            gl.vertexAttribI3uiv = @ptrCast(getExtProcAddress("glVertexAttribI3uiv"));
            gl.vertexAttribI4uiv = @ptrCast(getExtProcAddress("glVertexAttribI4uiv"));
            gl.vertexAttribI4bv = @ptrCast(getExtProcAddress("glVertexAttribI4bv"));
            gl.vertexAttribI4sv = @ptrCast(getExtProcAddress("glVertexAttribI4sv"));
            gl.vertexAttribI4ubv = @ptrCast(getExtProcAddress("glVertexAttribI4ubv"));
            gl.vertexAttribI4usv = @ptrCast(getExtProcAddress("glVertexAttribI4usv"));
            gl.getUniformuiv = @ptrCast(getExtProcAddress("glGetUniformuiv"));
            gl.bindFragDataLocation = @ptrCast(getExtProcAddress("glBindFragDataLocation"));
            gl.getFragDataLocation = @ptrCast(getExtProcAddress("glGetFragDataLocation"));
            gl.uniform1ui = @ptrCast(getExtProcAddress("glUniform1ui"));
            gl.uniform2ui = @ptrCast(getExtProcAddress("glUniform2ui"));
            gl.uniform3ui = @ptrCast(getExtProcAddress("glUniform3ui"));
            gl.uniform4ui = @ptrCast(getExtProcAddress("glUniform4ui"));
            gl.uniform1uiv = @ptrCast(getExtProcAddress("glUniform1uiv"));
            gl.uniform2uiv = @ptrCast(getExtProcAddress("glUniform2uiv"));
            gl.uniform3uiv = @ptrCast(getExtProcAddress("glUniform3uiv"));
            gl.uniform4uiv = @ptrCast(getExtProcAddress("glUniform4uiv"));
            gl.texParameterIiv = @ptrCast(getExtProcAddress("glTexParameterIiv"));
            gl.texParameterIuiv = @ptrCast(getExtProcAddress("glTexParameterIuiv"));
            gl.getTexParameterIiv = @ptrCast(getExtProcAddress("glGetTexParameterIiv"));
            gl.getTexParameterIuiv = @ptrCast(getExtProcAddress("glGetTexParameterIuiv"));
            gl.clearBufferiv = @ptrCast(getExtProcAddress("glClearBufferiv"));
            gl.clearBufferuiv = @ptrCast(getExtProcAddress("glClearBufferuiv"));
            gl.clearBufferfv = @ptrCast(getExtProcAddress("glClearBufferfv"));
            gl.clearBufferfi = @ptrCast(getExtProcAddress("glClearBufferfi"));
            gl.getStringi = @ptrCast(getExtProcAddress("glGetStringi"));
            gl.isRenderbuffer = @ptrCast(getExtProcAddress("glIsRenderbuffer"));
            gl.bindRenderbuffer = @ptrCast(getExtProcAddress("glBindRenderbuffer"));
            gl.deleteRenderbuffers = @ptrCast(getExtProcAddress("glDeleteRenderbuffers"));
            gl.genRenderbuffers = @ptrCast(getExtProcAddress("glGenRenderbuffers"));
            gl.renderbufferStorage = @ptrCast(getExtProcAddress("glRenderbufferStorage"));
            gl.getRenderbufferParameteriv = @ptrCast(getExtProcAddress("glGetRenderbufferParameteriv"));
            gl.isFramebuffer = @ptrCast(getExtProcAddress("glIsFramebuffer"));
            gl.bindFramebuffer = @ptrCast(getExtProcAddress("glBindFramebuffer"));
            gl.deleteFramebuffers = @ptrCast(getExtProcAddress("glDeleteFramebuffers"));
            gl.genFramebuffers = @ptrCast(getExtProcAddress("glGenFramebuffers"));
            gl.checkFramebufferStatus = @ptrCast(getExtProcAddress("glCheckFramebufferStatus"));
            gl.framebufferTexture1D = @ptrCast(getExtProcAddress("glFramebufferTexture1D"));
            gl.framebufferTexture2D = @ptrCast(getExtProcAddress("glFramebufferTexture2D"));
            gl.framebufferTexture3D = @ptrCast(getExtProcAddress("glFramebufferTexture3D"));
            gl.framebufferRenderbuffer = @ptrCast(getExtProcAddress("glFramebufferRenderbuffer"));
            gl.getFramebufferAttachmentParameteriv = @ptrCast(getExtProcAddress("glGetFramebufferAttachmentParameteriv"));
            gl.generateMipmap = @ptrCast(getExtProcAddress("glGenerateMipmap"));
            gl.blitFramebuffer = @ptrCast(getExtProcAddress("glBlitFramebuffer"));
            gl.renderbufferStorageMultisample = @ptrCast(getExtProcAddress("glRenderbufferStorageMultisample"));
            gl.framebufferTextureLayer = @ptrCast(getExtProcAddress("glFramebufferTextureLayer"));
            gl.mapBufferRange = @ptrCast(getExtProcAddress("glMapBufferRange"));
            gl.flushMappedBufferRange = @ptrCast(getExtProcAddress("glFlushMappedBufferRange"));
            gl.bindVertexArray = @ptrCast(getExtProcAddress("glBindVertexArray"));
            gl.deleteVertexArrays = @ptrCast(getExtProcAddress("glDeleteVertexArrays"));
            gl.genVertexArrays = @ptrCast(getExtProcAddress("glGenVertexArrays"));
            gl.isVertexArray = @ptrCast(getExtProcAddress("glIsVertexArray"));
        }

        if (version >= 310) {
            gl.drawArraysInstanced = @ptrCast(getExtProcAddress("glDrawArraysInstanced"));
            gl.drawElementsInstanced = @ptrCast(getExtProcAddress("glDrawElementsInstanced"));
            gl.texBuffer = @ptrCast(getExtProcAddress("glTexBuffer"));
            gl.primitiveRestartIndex = @ptrCast(getExtProcAddress("glPrimitiveRestartIndex"));
            gl.copyBufferSubData = @ptrCast(getExtProcAddress("glCopyBufferSubData"));
            gl.getUniformIndices = @ptrCast(getExtProcAddress("glGetUniformIndices"));
            gl.getActiveUniformsiv = @ptrCast(getExtProcAddress("glGetActiveUniformsiv"));
            gl.getActiveUniformName = @ptrCast(getExtProcAddress("glGetActiveUniformName"));
            gl.getUniformBlockIndex = @ptrCast(getExtProcAddress("glGetUniformBlockIndex"));
            gl.getActiveUniformBlockiv = @ptrCast(getExtProcAddress("glGetActiveUniformBlockiv"));
            gl.getActiveUniformBlockName = @ptrCast(getExtProcAddress("glGetActiveUniformBlockName"));
            gl.uniformBlockBinding = @ptrCast(getExtProcAddress("glUniformBlockBinding"));
        }

        if (version >= 320) {
            gl.drawElementsBaseVertex = @ptrCast(getExtProcAddress("glDrawElementsBaseVertex"));
            gl.drawRangeElementsBaseVertex = @ptrCast(getExtProcAddress("glDrawRangeElementsBaseVertex"));
            gl.drawElementsInstancedBaseVertex = @ptrCast(getExtProcAddress("glDrawElementsInstancedBaseVertex"));
            gl.multiDrawElementsBaseVertex = @ptrCast(getExtProcAddress("glMultiDrawElementsBaseVertex"));
            gl.provokingVertex = @ptrCast(getExtProcAddress("glProvokingVertex"));
            gl.fenceSync = @ptrCast(getExtProcAddress("glFenceSync"));
            gl.isSync = @ptrCast(getExtProcAddress("glIsSync"));
            gl.deleteSync = @ptrCast(getExtProcAddress("glDeleteSync"));
            gl.clientWaitSync = @ptrCast(getExtProcAddress("glClientWaitSync"));
            gl.waitSync = @ptrCast(getExtProcAddress("glWaitSync"));
            gl.getInteger64v = @ptrCast(getExtProcAddress("glGetInteger64v"));
            gl.getSynciv = @ptrCast(getExtProcAddress("glGetSynciv"));
            gl.getInteger64i_v = @ptrCast(getExtProcAddress("glGetInteger64i_v"));
            gl.getBufferParameteri64v = @ptrCast(getExtProcAddress("glGetBufferParameteri64v"));
            gl.framebufferTexture = @ptrCast(getExtProcAddress("glFramebufferTexture"));
            gl.texImage2DMultisample = @ptrCast(getExtProcAddress("glTexImage2DMultisample"));
            gl.texImage3DMultisample = @ptrCast(getExtProcAddress("glTexImage3DMultisample"));
            gl.getMultisamplefv = @ptrCast(getExtProcAddress("glGetMultisamplefv"));
            gl.sampleMaski = @ptrCast(getExtProcAddress("glSampleMaski"));
        }

        if (version >= 330) {
            gl.bindFragDataLocationIndexed = @ptrCast(getExtProcAddress("glBindFragDataLocationIndexed"));
            gl.getFragDataIndex = @ptrCast(getExtProcAddress("glGetFragDataIndex"));
            gl.genSamplers = @ptrCast(getExtProcAddress("glGenSamplers"));
            gl.deleteSamplers = @ptrCast(getExtProcAddress("glDeleteSamplers"));
            gl.isSampler = @ptrCast(getExtProcAddress("glIsSampler"));
            gl.bindSampler = @ptrCast(getExtProcAddress("glBindSampler"));
            gl.samplerParameteri = @ptrCast(getExtProcAddress("glSamplerParameteri"));
            gl.samplerParameteriv = @ptrCast(getExtProcAddress("glSamplerParameteriv"));
            gl.samplerParameterf = @ptrCast(getExtProcAddress("glSamplerParameterf"));
            gl.samplerParameterfv = @ptrCast(getExtProcAddress("glSamplerParameterfv"));
            gl.samplerParameterIiv = @ptrCast(getExtProcAddress("glSamplerParameterIiv"));
            gl.samplerParameterIuiv = @ptrCast(getExtProcAddress("glSamplerParameterIuiv"));
            gl.getSamplerParameteriv = @ptrCast(getExtProcAddress("glGetSamplerParameteriv"));
            gl.getSamplerParameterIiv = @ptrCast(getExtProcAddress("glGetSamplerParameterIiv"));
            gl.getSamplerParameterfv = @ptrCast(getExtProcAddress("glGetSamplerParameterfv"));
            gl.getSamplerParameterIuiv = @ptrCast(getExtProcAddress("glGetSamplerParameterIuiv"));
            gl.queryCounter = @ptrCast(getExtProcAddress("glQueryCounter"));
            gl.getQueryObjecti64v = @ptrCast(getExtProcAddress("glGetQueryObjecti64v"));
            gl.getQueryObjectui64v = @ptrCast(getExtProcAddress("glGetQueryObjectui64v"));
            gl.vertexAttribDivisor = @ptrCast(getExtProcAddress("glVertexAttribDivisor"));
            gl.vertexAttribP1ui = @ptrCast(getExtProcAddress("glVertexAttribP1ui"));
            gl.vertexAttribP1uiv = @ptrCast(getExtProcAddress("glVertexAttribP1uiv"));
            gl.vertexAttribP2ui = @ptrCast(getExtProcAddress("glVertexAttribP2ui"));
            gl.vertexAttribP2uiv = @ptrCast(getExtProcAddress("glVertexAttribP2uiv"));
            gl.vertexAttribP3ui = @ptrCast(getExtProcAddress("glVertexAttribP3ui"));
            gl.vertexAttribP3uiv = @ptrCast(getExtProcAddress("glVertexAttribP3uiv"));
            gl.vertexAttribP4ui = @ptrCast(getExtProcAddress("glVertexAttribP4ui"));
            gl.vertexAttribP4uiv = @ptrCast(getExtProcAddress("glVertexAttribP4uiv"));
        }

        if (version >= 400) {
            gl.minSampleShading = @ptrCast(getExtProcAddress("glMinSampleShading"));
            gl.blendEquationi = @ptrCast(getExtProcAddress("glBlendEquationi"));
            gl.blendEquationSeparatei = @ptrCast(getExtProcAddress("glBlendEquationSeparatei"));
            gl.blendFunci = @ptrCast(getExtProcAddress("glBlendFunci"));
            gl.blendFuncSeparatei = @ptrCast(getExtProcAddress("glBlendFuncSeparatei"));
            gl.drawArraysIndirect = @ptrCast(getExtProcAddress("glDrawArraysIndirect"));
            gl.drawElementsIndirect = @ptrCast(getExtProcAddress("glDrawElementsIndirect"));
            gl.uniform1d = @ptrCast(getExtProcAddress("glUniform1d"));
            gl.uniform2d = @ptrCast(getExtProcAddress("glUniform2d"));
            gl.uniform3d = @ptrCast(getExtProcAddress("glUniform3d"));
            gl.uniform4d = @ptrCast(getExtProcAddress("glUniform4d"));
            gl.uniform1dv = @ptrCast(getExtProcAddress("glUniform1dv"));
            gl.uniform2dv = @ptrCast(getExtProcAddress("glUniform2dv"));
            gl.uniform3dv = @ptrCast(getExtProcAddress("glUniform3dv"));
            gl.uniform4dv = @ptrCast(getExtProcAddress("glUniform4dv"));
            gl.uniformMatrix2dv = @ptrCast(getExtProcAddress("glUniformMatrix2dv"));
            gl.uniformMatrix3dv = @ptrCast(getExtProcAddress("glUniformMatrix3dv"));
            gl.uniformMatrix4dv = @ptrCast(getExtProcAddress("glUniformMatrix4dv"));
            gl.uniformMatrix2x3dv = @ptrCast(getExtProcAddress("glUniformMatrix2x3dv"));
            gl.uniformMatrix2x4dv = @ptrCast(getExtProcAddress("glUniformMatrix2x4dv"));
            gl.uniformMatrix3x2dv = @ptrCast(getExtProcAddress("glUniformMatrix3x2dv"));
            gl.uniformMatrix3x4dv = @ptrCast(getExtProcAddress("glUniformMatrix3x4dv"));
            gl.uniformMatrix4x2dv = @ptrCast(getExtProcAddress("glUniformMatrix4x2dv"));
            gl.uniformMatrix4x3dv = @ptrCast(getExtProcAddress("glUniformMatrix4x3dv"));
            gl.getUniformdv = @ptrCast(getExtProcAddress("glGetUniformdv"));
            gl.getSubroutineUniformLocation = @ptrCast(getExtProcAddress("glGetSubroutineUniformLocation"));
            gl.getSubroutineIndex = @ptrCast(getExtProcAddress("glGetSubroutineIndex"));
            gl.getActiveSubroutineUniformiv = @ptrCast(getExtProcAddress("glGetActiveSubroutineUniformiv"));
            gl.getActiveSubroutineUniformName = @ptrCast(getExtProcAddress("glGetActiveSubroutineUniformName"));
            gl.getActiveSubroutineName = @ptrCast(getExtProcAddress("glGetActiveSubroutineName"));
            gl.uniformSubroutinesuiv = @ptrCast(getExtProcAddress("glUniformSubroutinesuiv"));
            gl.getUniformSubroutineuiv = @ptrCast(getExtProcAddress("glGetUniformSubroutineuiv"));
            gl.getProgramStageiv = @ptrCast(getExtProcAddress("glGetProgramStageiv"));
            gl.patchParameteri = @ptrCast(getExtProcAddress("glPatchParameteri"));
            gl.patchParameterfv = @ptrCast(getExtProcAddress("glPatchParameterfv"));
            gl.bindTransformFeedback = @ptrCast(getExtProcAddress("glBindTransformFeedback"));
            gl.deleteTransformFeedbacks = @ptrCast(getExtProcAddress("glDeleteTransformFeedbacks"));
            gl.genTransformFeedbacks = @ptrCast(getExtProcAddress("glGenTransformFeedbacks"));
            gl.isTransformFeedback = @ptrCast(getExtProcAddress("glIsTransformFeedback"));
            gl.pauseTransformFeedback = @ptrCast(getExtProcAddress("glPauseTransformFeedback"));
            gl.resumeTransformFeedback = @ptrCast(getExtProcAddress("glResumeTransformFeedback"));
            gl.drawTransformFeedback = @ptrCast(getExtProcAddress("glDrawTransformFeedback"));
            gl.drawTransformFeedbackStream = @ptrCast(getExtProcAddress("glDrawTransformFeedbackStream"));
            gl.beginQueryIndexed = @ptrCast(getExtProcAddress("glBeginQueryIndexed"));
            gl.endQueryIndexed = @ptrCast(getExtProcAddress("glEndQueryIndexed"));
            gl.getQueryIndexediv = @ptrCast(getExtProcAddress("glGetQueryIndexediv"));
        }

        if (version >= 410) {
            gl.releaseShaderCompiler = @ptrCast(getExtProcAddress("glReleaseShaderCompiler"));
            gl.shaderBinary = @ptrCast(getExtProcAddress("glShaderBinary"));
            gl.getShaderPrecisionFormat = @ptrCast(getExtProcAddress("glGetShaderPrecisionFormat"));
            gl.depthRangef = @ptrCast(getExtProcAddress("glDepthRangef"));
            gl.clearDepthf = @ptrCast(getExtProcAddress("glClearDepthf"));
            gl.getProgramBinary = @ptrCast(getExtProcAddress("glGetProgramBinary"));
            gl.programBinary = @ptrCast(getExtProcAddress("glProgramBinary"));
            gl.programParameteri = @ptrCast(getExtProcAddress("glProgramParameteri"));
            gl.useProgramStages = @ptrCast(getExtProcAddress("glUseProgramStages"));
            gl.activeShaderProgram = @ptrCast(getExtProcAddress("glActiveShaderProgram"));
            gl.createShaderProgramv = @ptrCast(getExtProcAddress("glCreateShaderProgramv"));
            gl.bindProgramPipeline = @ptrCast(getExtProcAddress("glBindProgramPipeline"));
            gl.deleteProgramPipelines = @ptrCast(getExtProcAddress("glDeleteProgramPipelines"));
            gl.genProgramPipelines = @ptrCast(getExtProcAddress("glGenProgramPipelines"));
            gl.isProgramPipeline = @ptrCast(getExtProcAddress("glIsProgramPipeline"));
            gl.getProgramPipelineiv = @ptrCast(getExtProcAddress("glGetProgramPipelineiv"));
            gl.programUniform1i = @ptrCast(getExtProcAddress("glProgramUniform1i"));
            gl.programUniform1iv = @ptrCast(getExtProcAddress("glProgramUniform1iv"));
            gl.programUniform1f = @ptrCast(getExtProcAddress("glProgramUniform1f"));
            gl.programUniform1fv = @ptrCast(getExtProcAddress("glProgramUniform1fv"));
            gl.programUniform1d = @ptrCast(getExtProcAddress("glProgramUniform1d"));
            gl.programUniform1dv = @ptrCast(getExtProcAddress("glProgramUniform1dv"));
            gl.programUniform1ui = @ptrCast(getExtProcAddress("glProgramUniform1ui"));
            gl.programUniform1uiv = @ptrCast(getExtProcAddress("glProgramUniform1uiv"));
            gl.programUniform2i = @ptrCast(getExtProcAddress("glProgramUniform2i"));
            gl.programUniform2iv = @ptrCast(getExtProcAddress("glProgramUniform2iv"));
            gl.programUniform2f = @ptrCast(getExtProcAddress("glProgramUniform2f"));
            gl.programUniform2fv = @ptrCast(getExtProcAddress("glProgramUniform2fv"));
            gl.programUniform2d = @ptrCast(getExtProcAddress("glProgramUniform2d"));
            gl.programUniform2dv = @ptrCast(getExtProcAddress("glProgramUniform2dv"));
            gl.programUniform2ui = @ptrCast(getExtProcAddress("glProgramUniform2ui"));
            gl.programUniform2uiv = @ptrCast(getExtProcAddress("glProgramUniform2uiv"));
            gl.programUniform3i = @ptrCast(getExtProcAddress("glProgramUniform3i"));
            gl.programUniform3iv = @ptrCast(getExtProcAddress("glProgramUniform3iv"));
            gl.programUniform3f = @ptrCast(getExtProcAddress("glProgramUniform3f"));
            gl.programUniform3fv = @ptrCast(getExtProcAddress("glProgramUniform3fv"));
            gl.programUniform3d = @ptrCast(getExtProcAddress("glProgramUniform3d"));
            gl.programUniform3dv = @ptrCast(getExtProcAddress("glProgramUniform3dv"));
            gl.programUniform3ui = @ptrCast(getExtProcAddress("glProgramUniform3ui"));
            gl.programUniform3uiv = @ptrCast(getExtProcAddress("glProgramUniform3uiv"));
            gl.programUniform4i = @ptrCast(getExtProcAddress("glProgramUniform4i"));
            gl.programUniform4iv = @ptrCast(getExtProcAddress("glProgramUniform4iv"));
            gl.programUniform4f = @ptrCast(getExtProcAddress("glProgramUniform4f"));
            gl.programUniform4fv = @ptrCast(getExtProcAddress("glProgramUniform4fv"));
            gl.programUniform4d = @ptrCast(getExtProcAddress("glProgramUniform4d"));
            gl.programUniform4dv = @ptrCast(getExtProcAddress("glProgramUniform4dv"));
            gl.programUniform4ui = @ptrCast(getExtProcAddress("glProgramUniform4ui"));
            gl.programUniform4uiv = @ptrCast(getExtProcAddress("glProgramUniform4uiv"));
            gl.programUniformMatrix2fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2fv"));
            gl.programUniformMatrix3fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3fv"));
            gl.programUniformMatrix4fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4fv"));
            gl.programUniformMatrix2dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2dv"));
            gl.programUniformMatrix3dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3dv"));
            gl.programUniformMatrix4dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4dv"));
            gl.programUniformMatrix2x3fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2x3fv"));
            gl.programUniformMatrix3x2fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3x2fv"));
            gl.programUniformMatrix2x4fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2x4fv"));
            gl.programUniformMatrix4x2fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4x2fv"));
            gl.programUniformMatrix3x4fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3x4fv"));
            gl.programUniformMatrix4x3fv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4x3fv"));
            gl.programUniformMatrix2x3dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2x3dv"));
            gl.programUniformMatrix3x2dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3x2dv"));
            gl.programUniformMatrix2x4dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix2x4dv"));
            gl.programUniformMatrix4x2dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4x2dv"));
            gl.programUniformMatrix3x4dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix3x4dv"));
            gl.programUniformMatrix4x3dv = @ptrCast(getExtProcAddress("glProgramUniformMatrix4x3dv"));
            gl.validateProgramPipeline = @ptrCast(getExtProcAddress("glValidateProgramPipeline"));
            gl.getProgramPipelineInfoLog = @ptrCast(getExtProcAddress("glGetProgramPipelineInfoLog"));
            gl.vertexAttribL1d = @ptrCast(getExtProcAddress("glVertexAttribL1d"));
            gl.vertexAttribL2d = @ptrCast(getExtProcAddress("glVertexAttribL2d"));
            gl.vertexAttribL3d = @ptrCast(getExtProcAddress("glVertexAttribL3d"));
            gl.vertexAttribL4d = @ptrCast(getExtProcAddress("glVertexAttribL4d"));
            gl.vertexAttribL1dv = @ptrCast(getExtProcAddress("glVertexAttribL1dv"));
            gl.vertexAttribL2dv = @ptrCast(getExtProcAddress("glVertexAttribL2dv"));
            gl.vertexAttribL3dv = @ptrCast(getExtProcAddress("glVertexAttribL3dv"));
            gl.vertexAttribL4dv = @ptrCast(getExtProcAddress("glVertexAttribL4dv"));
            gl.vertexAttribLPointer = @ptrCast(getExtProcAddress("glVertexAttribLPointer"));
            gl.getVertexAttribLdv = @ptrCast(getExtProcAddress("glGetVertexAttribLdv"));
            gl.viewportArrayv = @ptrCast(getExtProcAddress("glViewportArrayv"));
            gl.viewportIndexedf = @ptrCast(getExtProcAddress("glViewportIndexedf"));
            gl.viewportIndexedfv = @ptrCast(getExtProcAddress("glViewportIndexedfv"));
            gl.scissorArrayv = @ptrCast(getExtProcAddress("glScissorArrayv"));
            gl.scissorIndexed = @ptrCast(getExtProcAddress("glScissorIndexed"));
            gl.scissorIndexedv = @ptrCast(getExtProcAddress("glScissorIndexedv"));
            gl.depthRangeArrayv = @ptrCast(getExtProcAddress("glDepthRangeArrayv"));
            gl.depthRangeIndexed = @ptrCast(getExtProcAddress("glDepthRangeIndexed"));
            gl.getFloati_v = @ptrCast(getExtProcAddress("glGetFloati_v"));
            gl.getDoublei_v = @ptrCast(getExtProcAddress("glGetDoublei_v"));
        }

        if (version >= 420) {
            gl.drawArraysInstancedBaseInstance = @ptrCast(getExtProcAddress("glDrawArraysInstancedBaseInstance"));
            gl.drawElementsInstancedBaseInstance = @ptrCast(getExtProcAddress("glDrawElementsInstancedBaseInstance"));
            gl.drawElementsInstancedBaseVertexBaseInstance = @ptrCast(getExtProcAddress("glDrawElementsInstancedBaseVertexBaseInstance"));
            gl.getInternalformativ = @ptrCast(getExtProcAddress("glGetInternalformativ"));
            gl.getActiveAtomicCounterBufferiv = @ptrCast(getExtProcAddress("glGetActiveAtomicCounterBufferiv"));
            gl.bindImageTexture = @ptrCast(getExtProcAddress("glBindImageTexture"));
            gl.memoryBarrier = @ptrCast(getExtProcAddress("glMemoryBarrier"));
            gl.texStorage1D = @ptrCast(getExtProcAddress("glTexStorage1D"));
            gl.texStorage2D = @ptrCast(getExtProcAddress("glTexStorage2D"));
            gl.texStorage3D = @ptrCast(getExtProcAddress("glTexStorage3D"));
            gl.drawTransformFeedbackInstanced = @ptrCast(getExtProcAddress("glDrawTransformFeedbackInstanced"));
            gl.drawTransformFeedbackStreamInstanced = @ptrCast(getExtProcAddress("glDrawTransformFeedbackStreamInstanced"));
        }

        if (version >= 430) {
            gl.clearBufferData = @ptrCast(getExtProcAddress("glClearBufferData"));
            gl.clearBufferSubData = @ptrCast(getExtProcAddress("glClearBufferSubData"));
            gl.dispatchCompute = @ptrCast(getExtProcAddress("glDispatchCompute"));
            gl.dispatchComputeIndirect = @ptrCast(getExtProcAddress("glDispatchComputeIndirect"));
            gl.copyImageSubData = @ptrCast(getExtProcAddress("glCopyImageSubData"));
            gl.framebufferParameteri = @ptrCast(getExtProcAddress("glFramebufferParameteri"));
            gl.getFramebufferParameteriv = @ptrCast(getExtProcAddress("glGetFramebufferParameteriv"));
            gl.getInternalformati64v = @ptrCast(getExtProcAddress("glGetInternalformati64v"));
            gl.invalidateTexSubImage = @ptrCast(getExtProcAddress("glInvalidateTexSubImage"));
            gl.invalidateTexImage = @ptrCast(getExtProcAddress("glInvalidateTexImage"));
            gl.invalidateBufferSubData = @ptrCast(getExtProcAddress("glInvalidateBufferSubData"));
            gl.invalidateBufferData = @ptrCast(getExtProcAddress("glInvalidateBufferData"));
            gl.invalidateFramebuffer = @ptrCast(getExtProcAddress("glInvalidateFramebuffer"));
            gl.invalidateSubFramebuffer = @ptrCast(getExtProcAddress("glInvalidateSubFramebuffer"));
            gl.multiDrawArraysIndirect = @ptrCast(getExtProcAddress("glMultiDrawArraysIndirect"));
            gl.multiDrawElementsIndirect = @ptrCast(getExtProcAddress("glMultiDrawElementsIndirect"));
            gl.getProgramInterfaceiv = @ptrCast(getExtProcAddress("glGetProgramInterfaceiv"));
            gl.getProgramResourceIndex = @ptrCast(getExtProcAddress("glGetProgramResourceIndex"));
            gl.getProgramResourceName = @ptrCast(getExtProcAddress("glGetProgramResourceName"));
            gl.getProgramResourceiv = @ptrCast(getExtProcAddress("glGetProgramResourceiv"));
            gl.getProgramResourceLocation = @ptrCast(getExtProcAddress("glGetProgramResourceLocation"));
            gl.getProgramResourceLocationIndex = @ptrCast(getExtProcAddress("glGetProgramResourceLocationIndex"));
            gl.shaderStorageBlockBinding = @ptrCast(getExtProcAddress("glShaderStorageBlockBinding"));
            gl.texBufferRange = @ptrCast(getExtProcAddress("glTexBufferRange"));
            gl.texStorage2DMultisample = @ptrCast(getExtProcAddress("glTexStorage2DMultisample"));
            gl.texStorage3DMultisample = @ptrCast(getExtProcAddress("glTexStorage3DMultisample"));
            gl.textureView = @ptrCast(getExtProcAddress("glTextureView"));
            gl.bindVertexBuffer = @ptrCast(getExtProcAddress("glBindVertexBuffer"));
            gl.vertexAttribFormat = @ptrCast(getExtProcAddress("glVertexAttribFormat"));
            gl.vertexAttribIFormat = @ptrCast(getExtProcAddress("glVertexAttribIFormat"));
            gl.vertexAttribLFormat = @ptrCast(getExtProcAddress("glVertexAttribLFormat"));
            gl.vertexAttribBinding = @ptrCast(getExtProcAddress("glVertexAttribBinding"));
            gl.vertexBindingDivisor = @ptrCast(getExtProcAddress("glVertexBindingDivisor"));
            gl.debugMessageControl = @ptrCast(getExtProcAddress("glDebugMessageControl"));
            gl.debugMessageInsert = @ptrCast(getExtProcAddress("glDebugMessageInsert"));
            gl.debugMessageCallback = @ptrCast(getExtProcAddress("glDebugMessageCallback"));
            gl.getDebugMessageLog = @ptrCast(getExtProcAddress("glGetDebugMessageLog"));
            gl.pushDebugGroup = @ptrCast(getExtProcAddress("glPushDebugGroup"));
            gl.popDebugGroup = @ptrCast(getExtProcAddress("glPopDebugGroup"));
            gl.objectLabel = @ptrCast(getExtProcAddress("glObjectLabel"));
            gl.getObjectLabel = @ptrCast(getExtProcAddress("glGetObjectLabel"));
            gl.objectPtrLabel = @ptrCast(getExtProcAddress("glObjectPtrLabel"));
            gl.getObjectPtrLabel = @ptrCast(getExtProcAddress("glGetObjectPtrLabel"));
        }

        if (version >= 440) {
            gl.bufferStorage = @ptrCast(getExtProcAddress("glBufferStorage"));
            gl.clearTexImage = @ptrCast(getExtProcAddress("glClearTexImage"));
            gl.clearTexSubImage = @ptrCast(getExtProcAddress("glClearTexSubImage"));
            gl.bindBuffersBase = @ptrCast(getExtProcAddress("glBindBuffersBase"));
            gl.bindBuffersRange = @ptrCast(getExtProcAddress("glBindBuffersRange"));
            gl.bindTextures = @ptrCast(getExtProcAddress("glBindTextures"));
            gl.bindSamplers = @ptrCast(getExtProcAddress("glBindSamplers"));
            gl.bindImageTextures = @ptrCast(getExtProcAddress("glBindImageTextures"));
            gl.bindVertexBuffers = @ptrCast(getExtProcAddress("glBindVertexBuffers"));
        }

        if (version >= 450) {
            gl.clipControl = @ptrCast(getExtProcAddress("glClipControl"));
            gl.createTransformFeedbacks = @ptrCast(getExtProcAddress("glCreateTransformFeedbacks"));
            gl.transformFeedbackBufferBase = @ptrCast(getExtProcAddress("glTransformFeedbackBufferBase"));
            gl.transformFeedbackBufferRange = @ptrCast(getExtProcAddress("glTransformFeedbackBufferRange"));
            gl.getTransformFeedbackiv = @ptrCast(getExtProcAddress("glGetTransformFeedbackiv"));
            gl.getTransformFeedbacki_v = @ptrCast(getExtProcAddress("glGetTransformFeedbacki_v"));
            gl.getTransformFeedbacki64_v = @ptrCast(getExtProcAddress("glGetTransformFeedbacki64_v"));
            gl.createBuffers = @ptrCast(getExtProcAddress("glCreateBuffers"));
            gl.namedBufferStorage = @ptrCast(getExtProcAddress("glNamedBufferStorage"));
            gl.namedBufferData = @ptrCast(getExtProcAddress("glNamedBufferData"));
            gl.namedBufferSubData = @ptrCast(getExtProcAddress("glNamedBufferSubData"));
            gl.copyNamedBufferSubData = @ptrCast(getExtProcAddress("glCopyNamedBufferSubData"));
            gl.clearNamedBufferData = @ptrCast(getExtProcAddress("glClearNamedBufferData"));
            gl.clearNamedBufferSubData = @ptrCast(getExtProcAddress("glClearNamedBufferSubData"));
            gl.mapNamedBuffer = @ptrCast(getExtProcAddress("glMapNamedBuffer"));
            gl.mapNamedBufferRange = @ptrCast(getExtProcAddress("glMapNamedBufferRange"));
            gl.unmapNamedBuffer = @ptrCast(getExtProcAddress("glUnmapNamedBuffer"));
            gl.flushMappedNamedBufferRange = @ptrCast(getExtProcAddress("glFlushMappedNamedBufferRange"));
            gl.getNamedBufferParameteriv = @ptrCast(getExtProcAddress("glGetNamedBufferParameteriv"));
            gl.getNamedBufferParameteri64v = @ptrCast(getExtProcAddress("glGetNamedBufferParameteri64v"));
            gl.getNamedBufferPointerv = @ptrCast(getExtProcAddress("glGetNamedBufferPointerv"));
            gl.getNamedBufferSubData = @ptrCast(getExtProcAddress("glGetNamedBufferSubData"));
            gl.createFramebuffers = @ptrCast(getExtProcAddress("glCreateFramebuffers"));
            gl.namedFramebufferRenderbuffer = @ptrCast(getExtProcAddress("glNamedFramebufferRenderbuffer"));
            gl.namedFramebufferParameteri = @ptrCast(getExtProcAddress("glNamedFramebufferParameteri"));
            gl.namedFramebufferTexture = @ptrCast(getExtProcAddress("glNamedFramebufferTexture"));
            gl.namedFramebufferTextureLayer = @ptrCast(getExtProcAddress("glNamedFramebufferTextureLayer"));
            gl.namedFramebufferDrawBuffer = @ptrCast(getExtProcAddress("glNamedFramebufferDrawBuffer"));
            gl.namedFramebufferDrawBuffers = @ptrCast(getExtProcAddress("glNamedFramebufferDrawBuffers"));
            gl.namedFramebufferReadBuffer = @ptrCast(getExtProcAddress("glNamedFramebufferReadBuffer"));
            gl.invalidateNamedFramebufferData = @ptrCast(getExtProcAddress("glInvalidateNamedFramebufferData"));
            gl.invalidateNamedFramebufferSubData = @ptrCast(getExtProcAddress("glInvalidateNamedFramebufferSubData"));
            gl.clearNamedFramebufferiv = @ptrCast(getExtProcAddress("glClearNamedFramebufferiv"));
            gl.clearNamedFramebufferuiv = @ptrCast(getExtProcAddress("glClearNamedFramebufferuiv"));
            gl.clearNamedFramebufferfv = @ptrCast(getExtProcAddress("glClearNamedFramebufferfv"));
            gl.clearNamedFramebufferfi = @ptrCast(getExtProcAddress("glClearNamedFramebufferfi"));
            gl.blitNamedFramebuffer = @ptrCast(getExtProcAddress("glBlitNamedFramebuffer"));
            gl.checkNamedFramebufferStatus = @ptrCast(getExtProcAddress("glCheckNamedFramebufferStatus"));
            gl.getNamedFramebufferParameteriv = @ptrCast(getExtProcAddress("glGetNamedFramebufferParameteriv"));
            gl.getNamedFramebufferAttachmentParameteriv = @ptrCast(getExtProcAddress("glGetNamedFramebufferAttachmentParameteriv"));
            gl.createRenderbuffers = @ptrCast(getExtProcAddress("glCreateRenderbuffers"));
            gl.namedRenderbufferStorage = @ptrCast(getExtProcAddress("glNamedRenderbufferStorage"));
            gl.namedRenderbufferStorageMultisample = @ptrCast(getExtProcAddress("glNamedRenderbufferStorageMultisample"));
            gl.getNamedRenderbufferParameteriv = @ptrCast(getExtProcAddress("glGetNamedRenderbufferParameteriv"));
            gl.createTextures = @ptrCast(getExtProcAddress("glCreateTextures"));
            gl.textureBuffer = @ptrCast(getExtProcAddress("glTextureBuffer"));
            gl.textureBufferRange = @ptrCast(getExtProcAddress("glTextureBufferRange"));
            gl.textureStorage1D = @ptrCast(getExtProcAddress("glTextureStorage1D"));
            gl.textureStorage2D = @ptrCast(getExtProcAddress("glTextureStorage2D"));
            gl.textureStorage3D = @ptrCast(getExtProcAddress("glTextureStorage3D"));
            gl.textureStorage2DMultisample = @ptrCast(getExtProcAddress("glTextureStorage2DMultisample"));
            gl.textureStorage3DMultisample = @ptrCast(getExtProcAddress("glTextureStorage3DMultisample"));
            gl.textureSubImage1D = @ptrCast(getExtProcAddress("glTextureSubImage1D"));
            gl.textureSubImage2D = @ptrCast(getExtProcAddress("glTextureSubImage2D"));
            gl.textureSubImage3D = @ptrCast(getExtProcAddress("glTextureSubImage3D"));
            gl.compressedTextureSubImage1D = @ptrCast(getExtProcAddress("glCompressedTextureSubImage1D"));
            gl.compressedTextureSubImage2D = @ptrCast(getExtProcAddress("glCompressedTextureSubImage2D"));
            gl.compressedTextureSubImage3D = @ptrCast(getExtProcAddress("glCompressedTextureSubImage3D"));
            gl.copyTextureSubImage1D = @ptrCast(getExtProcAddress("glCopyTextureSubImage1D"));
            gl.copyTextureSubImage2D = @ptrCast(getExtProcAddress("glCopyTextureSubImage2D"));
            gl.copyTextureSubImage3D = @ptrCast(getExtProcAddress("glCopyTextureSubImage3D"));
            gl.textureParameterf = @ptrCast(getExtProcAddress("glTextureParameterf"));
            gl.textureParameterfv = @ptrCast(getExtProcAddress("glTextureParameterfv"));
            gl.textureParameteri = @ptrCast(getExtProcAddress("glTextureParameteri"));
            gl.textureParameterIiv = @ptrCast(getExtProcAddress("glTextureParameterIiv"));
            gl.textureParameterIuiv = @ptrCast(getExtProcAddress("glTextureParameterIuiv"));
            gl.textureParameteriv = @ptrCast(getExtProcAddress("glTextureParameteriv"));
            gl.generateTextureMipmap = @ptrCast(getExtProcAddress("glGenerateTextureMipmap"));
            gl.bindTextureUnit = @ptrCast(getExtProcAddress("glBindTextureUnit"));
            gl.getTextureImage = @ptrCast(getExtProcAddress("glGetTextureImage"));
            gl.getCompressedTextureImage = @ptrCast(getExtProcAddress("glGetCompressedTextureImage"));
            gl.getTextureLevelParameterfv = @ptrCast(getExtProcAddress("glGetTextureLevelParameterfv"));
            gl.getTextureLevelParameteriv = @ptrCast(getExtProcAddress("glGetTextureLevelParameteriv"));
            gl.getTextureParameterfv = @ptrCast(getExtProcAddress("glGetTextureParameterfv"));
            gl.getTextureParameterIiv = @ptrCast(getExtProcAddress("glGetTextureParameterIiv"));
            gl.getTextureParameterIuiv = @ptrCast(getExtProcAddress("glGetTextureParameterIuiv"));
            gl.getTextureParameteriv = @ptrCast(getExtProcAddress("glGetTextureParameteriv"));
            gl.createVertexArrays = @ptrCast(getExtProcAddress("glCreateVertexArrays"));
            gl.disableVertexArrayAttrib = @ptrCast(getExtProcAddress("glDisableVertexArrayAttrib"));
            gl.enableVertexArrayAttrib = @ptrCast(getExtProcAddress("glEnableVertexArrayAttrib"));
            gl.vertexArrayElementBuffer = @ptrCast(getExtProcAddress("glVertexArrayElementBuffer"));
            gl.vertexArrayVertexBuffer = @ptrCast(getExtProcAddress("glVertexArrayVertexBuffer"));
            gl.vertexArrayVertexBuffers = @ptrCast(getExtProcAddress("glVertexArrayVertexBuffers"));
            gl.vertexArrayAttribBinding = @ptrCast(getExtProcAddress("glVertexArrayAttribBinding"));
            gl.vertexArrayAttribFormat = @ptrCast(getExtProcAddress("glVertexArrayAttribFormat"));
            gl.vertexArrayAttribIFormat = @ptrCast(getExtProcAddress("glVertexArrayAttribIFormat"));
            gl.vertexArrayAttribLFormat = @ptrCast(getExtProcAddress("glVertexArrayAttribLFormat"));
            gl.vertexArrayBindingDivisor = @ptrCast(getExtProcAddress("glVertexArrayBindingDivisor"));
            gl.getVertexArrayiv = @ptrCast(getExtProcAddress("glGetVertexArrayiv"));
            gl.getVertexArrayIndexediv = @ptrCast(getExtProcAddress("glGetVertexArrayIndexediv"));
            gl.getVertexArrayIndexed64iv = @ptrCast(getExtProcAddress("glGetVertexArrayIndexed64iv"));
            gl.createSamplers = @ptrCast(getExtProcAddress("glCreateSamplers"));
            gl.createProgramPipelines = @ptrCast(getExtProcAddress("glCreateProgramPipelines"));
            gl.createQueries = @ptrCast(getExtProcAddress("glCreateQueries"));
            gl.getQueryBufferObjecti64v = @ptrCast(getExtProcAddress("glGetQueryBufferObjecti64v"));
            gl.getQueryBufferObjectiv = @ptrCast(getExtProcAddress("glGetQueryBufferObjectiv"));
            gl.getQueryBufferObjectui64v = @ptrCast(getExtProcAddress("glGetQueryBufferObjectui64v"));
            gl.getQueryBufferObjectuiv = @ptrCast(getExtProcAddress("glGetQueryBufferObjectuiv"));
            gl.memoryBarrierByRegion = @ptrCast(getExtProcAddress("glMemoryBarrierByRegion"));
            gl.getTextureSubImage = @ptrCast(getExtProcAddress("glGetTextureSubImage"));
            gl.getCompressedTextureSubImage = @ptrCast(getExtProcAddress("glGetCompressedTextureSubImage"));
            gl.getGraphicsResetStatus = @ptrCast(getExtProcAddress("glGetGraphicsResetStatus"));
            gl.getnCompressedTexImage = @ptrCast(getExtProcAddress("glGetnCompressedTexImage"));
            gl.getnTexImage = @ptrCast(getExtProcAddress("glGetnTexImage"));
            gl.getnUniformdv = @ptrCast(getExtProcAddress("glGetnUniformdv"));
            gl.getnUniformfv = @ptrCast(getExtProcAddress("glGetnUniformfv"));
            gl.getnUniformiv = @ptrCast(getExtProcAddress("glGetnUniformiv"));
            gl.getnUniformuiv = @ptrCast(getExtProcAddress("glGetnUniformuiv"));
            gl.readnPixels = @ptrCast(getExtProcAddress("glReadnPixels"));
            gl.textureBarrier = @ptrCast(getExtProcAddress("glTextureBarrier"));
        }

        if (version >= 460) {
            gl.specializeShader = @ptrCast(getExtProcAddress("glSpecializeShader"));
            gl.multiDrawArraysIndirectCount = @ptrCast(getExtProcAddress("glMultiDrawArraysIndirectCount"));
            gl.multiDrawElementsIndirectCount = @ptrCast(getExtProcAddress("glMultiDrawElementsIndirectCount"));
            gl.polygonOffsetClamp = @ptrCast(getExtProcAddress("glPolygonOffsetClamp"));
        }
    }
};
