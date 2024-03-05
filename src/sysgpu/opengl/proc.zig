const std = @import("std");
const c = @import("c.zig");

var libgl: std.DynLib = undefined;

fn removeOptional(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Optional => |opt| opt.child,
        else => T,
    };
}

fn getProcAddress(name_ptr: [*:0]const u8) c.PROC {
    const name = std.mem.span(name_ptr);
    return libgl.lookup(removeOptional(c.PROC), name);
}

pub fn init() !void {
    libgl = try std.DynLib.openZ("opengl32.dll");
}

pub fn deinit() void {
    libgl.close();
}

pub const InstanceWGL = struct {
    getExtensionsStringARB: removeOptional(c.PFNWGLGETEXTENSIONSSTRINGARBPROC),
    createContextAttribsARB: removeOptional(c.PFNWGLCREATECONTEXTATTRIBSARBPROC),
    choosePixelFormatARB: removeOptional(c.PFNWGLCHOOSEPIXELFORMATARBPROC),

    pub fn load(wgl: *InstanceWGL) void {
        wgl.getExtensionsStringARB = @ptrCast(c.wglGetProcAddress("wglGetExtensionsStringARB"));
        wgl.createContextAttribsARB = @ptrCast(c.wglGetProcAddress("wglCreateContextAttribsARB"));
        wgl.choosePixelFormatARB = @ptrCast(c.wglGetProcAddress("wglChoosePixelFormatARB"));
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
            gl.drawRangeElements = @ptrCast(c.wglGetProcAddress("glDrawRangeElements"));
            gl.texImage3D = @ptrCast(c.wglGetProcAddress("glTexImage3D"));
            gl.texSubImage3D = @ptrCast(c.wglGetProcAddress("glTexSubImage3D"));
            gl.copyTexSubImage3D = @ptrCast(c.wglGetProcAddress("glCopyTexSubImage3D"));
        }

        if (version >= 130) {
            gl.activeTexture = @ptrCast(c.wglGetProcAddress("glActiveTexture"));
            gl.sampleCoverage = @ptrCast(c.wglGetProcAddress("glSampleCoverage"));
            gl.compressedTexImage3D = @ptrCast(c.wglGetProcAddress("glCompressedTexImage3D"));
            gl.compressedTexImage2D = @ptrCast(c.wglGetProcAddress("glCompressedTexImage2D"));
            gl.compressedTexImage1D = @ptrCast(c.wglGetProcAddress("glCompressedTexImage1D"));
            gl.compressedTexSubImage3D = @ptrCast(c.wglGetProcAddress("glCompressedTexSubImage3D"));
            gl.compressedTexSubImage2D = @ptrCast(c.wglGetProcAddress("glCompressedTexSubImage2D"));
            gl.compressedTexSubImage1D = @ptrCast(c.wglGetProcAddress("glCompressedTexSubImage1D"));
            gl.getCompressedTexImage = @ptrCast(c.wglGetProcAddress("glGetCompressedTexImage"));
        }

        if (version >= 140) {
            gl.blendFuncSeparate = @ptrCast(c.wglGetProcAddress("glBlendFuncSeparate"));
            gl.multiDrawArrays = @ptrCast(c.wglGetProcAddress("glMultiDrawArrays"));
            gl.multiDrawElements = @ptrCast(c.wglGetProcAddress("glMultiDrawElements"));
            gl.pointParameterf = @ptrCast(c.wglGetProcAddress("glPointParameterf"));
            gl.pointParameterfv = @ptrCast(c.wglGetProcAddress("glPointParameterfv"));
            gl.pointParameteri = @ptrCast(c.wglGetProcAddress("glPointParameteri"));
            gl.pointParameteriv = @ptrCast(c.wglGetProcAddress("glPointParameteriv"));
            gl.blendColor = @ptrCast(c.wglGetProcAddress("glBlendColor"));
            gl.blendEquation = @ptrCast(c.wglGetProcAddress("glBlendEquation"));
        }

        if (version >= 150) {
            gl.genQueries = @ptrCast(c.wglGetProcAddress("glGenQueries"));
            gl.deleteQueries = @ptrCast(c.wglGetProcAddress("glDeleteQueries"));
            gl.isQuery = @ptrCast(c.wglGetProcAddress("glIsQuery"));
            gl.beginQuery = @ptrCast(c.wglGetProcAddress("glBeginQuery"));
            gl.endQuery = @ptrCast(c.wglGetProcAddress("glEndQuery"));
            gl.getQueryiv = @ptrCast(c.wglGetProcAddress("glGetQueryiv"));
            gl.getQueryObjectiv = @ptrCast(c.wglGetProcAddress("glGetQueryObjectiv"));
            gl.getQueryObjectuiv = @ptrCast(c.wglGetProcAddress("glGetQueryObjectuiv"));
            gl.bindBuffer = @ptrCast(c.wglGetProcAddress("glBindBuffer"));
            gl.deleteBuffers = @ptrCast(c.wglGetProcAddress("glDeleteBuffers"));
            gl.genBuffers = @ptrCast(c.wglGetProcAddress("glGenBuffers"));
            gl.isBuffer = @ptrCast(c.wglGetProcAddress("glIsBuffer"));
            gl.bufferData = @ptrCast(c.wglGetProcAddress("glBufferData"));
            gl.bufferSubData = @ptrCast(c.wglGetProcAddress("glBufferSubData"));
            gl.getBufferSubData = @ptrCast(c.wglGetProcAddress("glGetBufferSubData"));
            gl.mapBuffer = @ptrCast(c.wglGetProcAddress("glMapBuffer"));
            gl.unmapBuffer = @ptrCast(c.wglGetProcAddress("glUnmapBuffer"));
            gl.getBufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetBufferParameteriv"));
            gl.getBufferPointerv = @ptrCast(c.wglGetProcAddress("glGetBufferPointerv"));
        }

        if (version >= 200) {
            gl.blendEquationSeparate = @ptrCast(c.wglGetProcAddress("glBlendEquationSeparate"));
            gl.drawBuffers = @ptrCast(c.wglGetProcAddress("glDrawBuffers"));
            gl.stencilOpSeparate = @ptrCast(c.wglGetProcAddress("glStencilOpSeparate"));
            gl.stencilFuncSeparate = @ptrCast(c.wglGetProcAddress("glStencilFuncSeparate"));
            gl.stencilMaskSeparate = @ptrCast(c.wglGetProcAddress("glStencilMaskSeparate"));
            gl.attachShader = @ptrCast(c.wglGetProcAddress("glAttachShader"));
            gl.bindAttribLocation = @ptrCast(c.wglGetProcAddress("glBindAttribLocation"));
            gl.compileShader = @ptrCast(c.wglGetProcAddress("glCompileShader"));
            gl.createProgram = @ptrCast(c.wglGetProcAddress("glCreateProgram"));
            gl.createShader = @ptrCast(c.wglGetProcAddress("glCreateShader"));
            gl.deleteProgram = @ptrCast(c.wglGetProcAddress("glDeleteProgram"));
            gl.deleteShader = @ptrCast(c.wglGetProcAddress("glDeleteShader"));
            gl.detachShader = @ptrCast(c.wglGetProcAddress("glDetachShader"));
            gl.disableVertexAttribArray = @ptrCast(c.wglGetProcAddress("glDisableVertexAttribArray"));
            gl.enableVertexAttribArray = @ptrCast(c.wglGetProcAddress("glEnableVertexAttribArray"));
            gl.getActiveAttrib = @ptrCast(c.wglGetProcAddress("glGetActiveAttrib"));
            gl.getActiveUniform = @ptrCast(c.wglGetProcAddress("glGetActiveUniform"));
            gl.getAttachedShaders = @ptrCast(c.wglGetProcAddress("glGetAttachedShaders"));
            gl.getAttribLocation = @ptrCast(c.wglGetProcAddress("glGetAttribLocation"));
            gl.getProgramiv = @ptrCast(c.wglGetProcAddress("glGetProgramiv"));
            gl.getProgramInfoLog = @ptrCast(c.wglGetProcAddress("glGetProgramInfoLog"));
            gl.getShaderiv = @ptrCast(c.wglGetProcAddress("glGetShaderiv"));
            gl.getShaderInfoLog = @ptrCast(c.wglGetProcAddress("glGetShaderInfoLog"));
            gl.getShaderSource = @ptrCast(c.wglGetProcAddress("glGetShaderSource"));
            gl.getUniformLocation = @ptrCast(c.wglGetProcAddress("glGetUniformLocation"));
            gl.getUniformfv = @ptrCast(c.wglGetProcAddress("glGetUniformfv"));
            gl.getUniformiv = @ptrCast(c.wglGetProcAddress("glGetUniformiv"));
            gl.getVertexAttribdv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribdv"));
            gl.getVertexAttribfv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribfv"));
            gl.getVertexAttribiv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribiv"));
            gl.getVertexAttribPointerv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribPointerv"));
            gl.isProgram = @ptrCast(c.wglGetProcAddress("glIsProgram"));
            gl.isShader = @ptrCast(c.wglGetProcAddress("glIsShader"));
            gl.linkProgram = @ptrCast(c.wglGetProcAddress("glLinkProgram"));
            gl.shaderSource = @ptrCast(c.wglGetProcAddress("glShaderSource"));
            gl.useProgram = @ptrCast(c.wglGetProcAddress("glUseProgram"));
            gl.uniform1f = @ptrCast(c.wglGetProcAddress("glUniform1f"));
            gl.uniform2f = @ptrCast(c.wglGetProcAddress("glUniform2f"));
            gl.uniform3f = @ptrCast(c.wglGetProcAddress("glUniform3f"));
            gl.uniform4f = @ptrCast(c.wglGetProcAddress("glUniform4f"));
            gl.uniform1i = @ptrCast(c.wglGetProcAddress("glUniform1i"));
            gl.uniform2i = @ptrCast(c.wglGetProcAddress("glUniform2i"));
            gl.uniform3i = @ptrCast(c.wglGetProcAddress("glUniform3i"));
            gl.uniform4i = @ptrCast(c.wglGetProcAddress("glUniform4i"));
            gl.uniform1fv = @ptrCast(c.wglGetProcAddress("glUniform1fv"));
            gl.uniform2fv = @ptrCast(c.wglGetProcAddress("glUniform2fv"));
            gl.uniform3fv = @ptrCast(c.wglGetProcAddress("glUniform3fv"));
            gl.uniform4fv = @ptrCast(c.wglGetProcAddress("glUniform4fv"));
            gl.uniform1iv = @ptrCast(c.wglGetProcAddress("glUniform1iv"));
            gl.uniform2iv = @ptrCast(c.wglGetProcAddress("glUniform2iv"));
            gl.uniform3iv = @ptrCast(c.wglGetProcAddress("glUniform3iv"));
            gl.uniform4iv = @ptrCast(c.wglGetProcAddress("glUniform4iv"));
            gl.uniformMatrix2fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2fv"));
            gl.uniformMatrix3fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3fv"));
            gl.uniformMatrix4fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4fv"));
            gl.validateProgram = @ptrCast(c.wglGetProcAddress("glValidateProgram"));
            gl.vertexAttrib1d = @ptrCast(c.wglGetProcAddress("glVertexAttrib1d"));
            gl.vertexAttrib1dv = @ptrCast(c.wglGetProcAddress("glVertexAttrib1dv"));
            gl.vertexAttrib1f = @ptrCast(c.wglGetProcAddress("glVertexAttrib1f"));
            gl.vertexAttrib1fv = @ptrCast(c.wglGetProcAddress("glVertexAttrib1fv"));
            gl.vertexAttrib1s = @ptrCast(c.wglGetProcAddress("glVertexAttrib1s"));
            gl.vertexAttrib1sv = @ptrCast(c.wglGetProcAddress("glVertexAttrib1sv"));
            gl.vertexAttrib2d = @ptrCast(c.wglGetProcAddress("glVertexAttrib2d"));
            gl.vertexAttrib2dv = @ptrCast(c.wglGetProcAddress("glVertexAttrib2dv"));
            gl.vertexAttrib2f = @ptrCast(c.wglGetProcAddress("glVertexAttrib2f"));
            gl.vertexAttrib2fv = @ptrCast(c.wglGetProcAddress("glVertexAttrib2fv"));
            gl.vertexAttrib2s = @ptrCast(c.wglGetProcAddress("glVertexAttrib2s"));
            gl.vertexAttrib2sv = @ptrCast(c.wglGetProcAddress("glVertexAttrib2sv"));
            gl.vertexAttrib3d = @ptrCast(c.wglGetProcAddress("glVertexAttrib3d"));
            gl.vertexAttrib3dv = @ptrCast(c.wglGetProcAddress("glVertexAttrib3dv"));
            gl.vertexAttrib3f = @ptrCast(c.wglGetProcAddress("glVertexAttrib3f"));
            gl.vertexAttrib3fv = @ptrCast(c.wglGetProcAddress("glVertexAttrib3fv"));
            gl.vertexAttrib3s = @ptrCast(c.wglGetProcAddress("glVertexAttrib3s"));
            gl.vertexAttrib3sv = @ptrCast(c.wglGetProcAddress("glVertexAttrib3sv"));
            gl.vertexAttrib4Nbv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nbv"));
            gl.vertexAttrib4Niv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Niv"));
            gl.vertexAttrib4Nsv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nsv"));
            gl.vertexAttrib4Nub = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nub"));
            gl.vertexAttrib4Nubv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nubv"));
            gl.vertexAttrib4Nuiv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nuiv"));
            gl.vertexAttrib4Nusv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4Nusv"));
            gl.vertexAttrib4bv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4bv"));
            gl.vertexAttrib4d = @ptrCast(c.wglGetProcAddress("glVertexAttrib4d"));
            gl.vertexAttrib4dv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4dv"));
            gl.vertexAttrib4f = @ptrCast(c.wglGetProcAddress("glVertexAttrib4f"));
            gl.vertexAttrib4fv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4fv"));
            gl.vertexAttrib4iv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4iv"));
            gl.vertexAttrib4s = @ptrCast(c.wglGetProcAddress("glVertexAttrib4s"));
            gl.vertexAttrib4sv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4sv"));
            gl.vertexAttrib4ubv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4ubv"));
            gl.vertexAttrib4uiv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4uiv"));
            gl.vertexAttrib4usv = @ptrCast(c.wglGetProcAddress("glVertexAttrib4usv"));
            gl.vertexAttribPointer = @ptrCast(c.wglGetProcAddress("glVertexAttribPointer"));
        }

        if (version >= 210) {
            gl.uniformMatrix2x3fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2x3fv"));
            gl.uniformMatrix3x2fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3x2fv"));
            gl.uniformMatrix2x4fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2x4fv"));
            gl.uniformMatrix4x2fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4x2fv"));
            gl.uniformMatrix3x4fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3x4fv"));
            gl.uniformMatrix4x3fv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4x3fv"));
        }

        if (version >= 300) {
            gl.colorMaski = @ptrCast(c.wglGetProcAddress("glColorMaski"));
            gl.getBooleani_v = @ptrCast(c.wglGetProcAddress("glGetBooleani_v"));
            gl.getIntegeri_v = @ptrCast(c.wglGetProcAddress("glGetIntegeri_v"));
            gl.enablei = @ptrCast(c.wglGetProcAddress("glEnablei"));
            gl.disablei = @ptrCast(c.wglGetProcAddress("glDisablei"));
            gl.isEnabledi = @ptrCast(c.wglGetProcAddress("glIsEnabledi"));
            gl.beginTransformFeedback = @ptrCast(c.wglGetProcAddress("glBeginTransformFeedback"));
            gl.endTransformFeedback = @ptrCast(c.wglGetProcAddress("glEndTransformFeedback"));
            gl.bindBufferRange = @ptrCast(c.wglGetProcAddress("glBindBufferRange"));
            gl.bindBufferBase = @ptrCast(c.wglGetProcAddress("glBindBufferBase"));
            gl.transformFeedbackVaryings = @ptrCast(c.wglGetProcAddress("glTransformFeedbackVaryings"));
            gl.getTransformFeedbackVarying = @ptrCast(c.wglGetProcAddress("glGetTransformFeedbackVarying"));
            gl.clampColor = @ptrCast(c.wglGetProcAddress("glClampColor"));
            gl.beginConditionalRender = @ptrCast(c.wglGetProcAddress("glBeginConditionalRender"));
            gl.endConditionalRender = @ptrCast(c.wglGetProcAddress("glEndConditionalRender"));
            gl.vertexAttribIPointer = @ptrCast(c.wglGetProcAddress("glVertexAttribIPointer"));
            gl.getVertexAttribIiv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribIiv"));
            gl.getVertexAttribIuiv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribIuiv"));
            gl.vertexAttribI1i = @ptrCast(c.wglGetProcAddress("glVertexAttribI1i"));
            gl.vertexAttribI2i = @ptrCast(c.wglGetProcAddress("glVertexAttribI2i"));
            gl.vertexAttribI3i = @ptrCast(c.wglGetProcAddress("glVertexAttribI3i"));
            gl.vertexAttribI4i = @ptrCast(c.wglGetProcAddress("glVertexAttribI4i"));
            gl.vertexAttribI1ui = @ptrCast(c.wglGetProcAddress("glVertexAttribI1ui"));
            gl.vertexAttribI2ui = @ptrCast(c.wglGetProcAddress("glVertexAttribI2ui"));
            gl.vertexAttribI3ui = @ptrCast(c.wglGetProcAddress("glVertexAttribI3ui"));
            gl.vertexAttribI4ui = @ptrCast(c.wglGetProcAddress("glVertexAttribI4ui"));
            gl.vertexAttribI1iv = @ptrCast(c.wglGetProcAddress("glVertexAttribI1iv"));
            gl.vertexAttribI2iv = @ptrCast(c.wglGetProcAddress("glVertexAttribI2iv"));
            gl.vertexAttribI3iv = @ptrCast(c.wglGetProcAddress("glVertexAttribI3iv"));
            gl.vertexAttribI4iv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4iv"));
            gl.vertexAttribI1uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribI1uiv"));
            gl.vertexAttribI2uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribI2uiv"));
            gl.vertexAttribI3uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribI3uiv"));
            gl.vertexAttribI4uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4uiv"));
            gl.vertexAttribI4bv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4bv"));
            gl.vertexAttribI4sv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4sv"));
            gl.vertexAttribI4ubv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4ubv"));
            gl.vertexAttribI4usv = @ptrCast(c.wglGetProcAddress("glVertexAttribI4usv"));
            gl.getUniformuiv = @ptrCast(c.wglGetProcAddress("glGetUniformuiv"));
            gl.bindFragDataLocation = @ptrCast(c.wglGetProcAddress("glBindFragDataLocation"));
            gl.getFragDataLocation = @ptrCast(c.wglGetProcAddress("glGetFragDataLocation"));
            gl.uniform1ui = @ptrCast(c.wglGetProcAddress("glUniform1ui"));
            gl.uniform2ui = @ptrCast(c.wglGetProcAddress("glUniform2ui"));
            gl.uniform3ui = @ptrCast(c.wglGetProcAddress("glUniform3ui"));
            gl.uniform4ui = @ptrCast(c.wglGetProcAddress("glUniform4ui"));
            gl.uniform1uiv = @ptrCast(c.wglGetProcAddress("glUniform1uiv"));
            gl.uniform2uiv = @ptrCast(c.wglGetProcAddress("glUniform2uiv"));
            gl.uniform3uiv = @ptrCast(c.wglGetProcAddress("glUniform3uiv"));
            gl.uniform4uiv = @ptrCast(c.wglGetProcAddress("glUniform4uiv"));
            gl.texParameterIiv = @ptrCast(c.wglGetProcAddress("glTexParameterIiv"));
            gl.texParameterIuiv = @ptrCast(c.wglGetProcAddress("glTexParameterIuiv"));
            gl.getTexParameterIiv = @ptrCast(c.wglGetProcAddress("glGetTexParameterIiv"));
            gl.getTexParameterIuiv = @ptrCast(c.wglGetProcAddress("glGetTexParameterIuiv"));
            gl.clearBufferiv = @ptrCast(c.wglGetProcAddress("glClearBufferiv"));
            gl.clearBufferuiv = @ptrCast(c.wglGetProcAddress("glClearBufferuiv"));
            gl.clearBufferfv = @ptrCast(c.wglGetProcAddress("glClearBufferfv"));
            gl.clearBufferfi = @ptrCast(c.wglGetProcAddress("glClearBufferfi"));
            gl.getStringi = @ptrCast(c.wglGetProcAddress("glGetStringi"));
            gl.isRenderbuffer = @ptrCast(c.wglGetProcAddress("glIsRenderbuffer"));
            gl.bindRenderbuffer = @ptrCast(c.wglGetProcAddress("glBindRenderbuffer"));
            gl.deleteRenderbuffers = @ptrCast(c.wglGetProcAddress("glDeleteRenderbuffers"));
            gl.genRenderbuffers = @ptrCast(c.wglGetProcAddress("glGenRenderbuffers"));
            gl.renderbufferStorage = @ptrCast(c.wglGetProcAddress("glRenderbufferStorage"));
            gl.getRenderbufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetRenderbufferParameteriv"));
            gl.isFramebuffer = @ptrCast(c.wglGetProcAddress("glIsFramebuffer"));
            gl.bindFramebuffer = @ptrCast(c.wglGetProcAddress("glBindFramebuffer"));
            gl.deleteFramebuffers = @ptrCast(c.wglGetProcAddress("glDeleteFramebuffers"));
            gl.genFramebuffers = @ptrCast(c.wglGetProcAddress("glGenFramebuffers"));
            gl.checkFramebufferStatus = @ptrCast(c.wglGetProcAddress("glCheckFramebufferStatus"));
            gl.framebufferTexture1D = @ptrCast(c.wglGetProcAddress("glFramebufferTexture1D"));
            gl.framebufferTexture2D = @ptrCast(c.wglGetProcAddress("glFramebufferTexture2D"));
            gl.framebufferTexture3D = @ptrCast(c.wglGetProcAddress("glFramebufferTexture3D"));
            gl.framebufferRenderbuffer = @ptrCast(c.wglGetProcAddress("glFramebufferRenderbuffer"));
            gl.getFramebufferAttachmentParameteriv = @ptrCast(c.wglGetProcAddress("glGetFramebufferAttachmentParameteriv"));
            gl.generateMipmap = @ptrCast(c.wglGetProcAddress("glGenerateMipmap"));
            gl.blitFramebuffer = @ptrCast(c.wglGetProcAddress("glBlitFramebuffer"));
            gl.renderbufferStorageMultisample = @ptrCast(c.wglGetProcAddress("glRenderbufferStorageMultisample"));
            gl.framebufferTextureLayer = @ptrCast(c.wglGetProcAddress("glFramebufferTextureLayer"));
            gl.mapBufferRange = @ptrCast(c.wglGetProcAddress("glMapBufferRange"));
            gl.flushMappedBufferRange = @ptrCast(c.wglGetProcAddress("glFlushMappedBufferRange"));
            gl.bindVertexArray = @ptrCast(c.wglGetProcAddress("glBindVertexArray"));
            gl.deleteVertexArrays = @ptrCast(c.wglGetProcAddress("glDeleteVertexArrays"));
            gl.genVertexArrays = @ptrCast(c.wglGetProcAddress("glGenVertexArrays"));
            gl.isVertexArray = @ptrCast(c.wglGetProcAddress("glIsVertexArray"));
        }

        if (version >= 310) {
            gl.drawArraysInstanced = @ptrCast(c.wglGetProcAddress("glDrawArraysInstanced"));
            gl.drawElementsInstanced = @ptrCast(c.wglGetProcAddress("glDrawElementsInstanced"));
            gl.texBuffer = @ptrCast(c.wglGetProcAddress("glTexBuffer"));
            gl.primitiveRestartIndex = @ptrCast(c.wglGetProcAddress("glPrimitiveRestartIndex"));
            gl.copyBufferSubData = @ptrCast(c.wglGetProcAddress("glCopyBufferSubData"));
            gl.getUniformIndices = @ptrCast(c.wglGetProcAddress("glGetUniformIndices"));
            gl.getActiveUniformsiv = @ptrCast(c.wglGetProcAddress("glGetActiveUniformsiv"));
            gl.getActiveUniformName = @ptrCast(c.wglGetProcAddress("glGetActiveUniformName"));
            gl.getUniformBlockIndex = @ptrCast(c.wglGetProcAddress("glGetUniformBlockIndex"));
            gl.getActiveUniformBlockiv = @ptrCast(c.wglGetProcAddress("glGetActiveUniformBlockiv"));
            gl.getActiveUniformBlockName = @ptrCast(c.wglGetProcAddress("glGetActiveUniformBlockName"));
            gl.uniformBlockBinding = @ptrCast(c.wglGetProcAddress("glUniformBlockBinding"));
        }

        if (version >= 320) {
            gl.drawElementsBaseVertex = @ptrCast(c.wglGetProcAddress("glDrawElementsBaseVertex"));
            gl.drawRangeElementsBaseVertex = @ptrCast(c.wglGetProcAddress("glDrawRangeElementsBaseVertex"));
            gl.drawElementsInstancedBaseVertex = @ptrCast(c.wglGetProcAddress("glDrawElementsInstancedBaseVertex"));
            gl.multiDrawElementsBaseVertex = @ptrCast(c.wglGetProcAddress("glMultiDrawElementsBaseVertex"));
            gl.provokingVertex = @ptrCast(c.wglGetProcAddress("glProvokingVertex"));
            gl.fenceSync = @ptrCast(c.wglGetProcAddress("glFenceSync"));
            gl.isSync = @ptrCast(c.wglGetProcAddress("glIsSync"));
            gl.deleteSync = @ptrCast(c.wglGetProcAddress("glDeleteSync"));
            gl.clientWaitSync = @ptrCast(c.wglGetProcAddress("glClientWaitSync"));
            gl.waitSync = @ptrCast(c.wglGetProcAddress("glWaitSync"));
            gl.getInteger64v = @ptrCast(c.wglGetProcAddress("glGetInteger64v"));
            gl.getSynciv = @ptrCast(c.wglGetProcAddress("glGetSynciv"));
            gl.getInteger64i_v = @ptrCast(c.wglGetProcAddress("glGetInteger64i_v"));
            gl.getBufferParameteri64v = @ptrCast(c.wglGetProcAddress("glGetBufferParameteri64v"));
            gl.framebufferTexture = @ptrCast(c.wglGetProcAddress("glFramebufferTexture"));
            gl.texImage2DMultisample = @ptrCast(c.wglGetProcAddress("glTexImage2DMultisample"));
            gl.texImage3DMultisample = @ptrCast(c.wglGetProcAddress("glTexImage3DMultisample"));
            gl.getMultisamplefv = @ptrCast(c.wglGetProcAddress("glGetMultisamplefv"));
            gl.sampleMaski = @ptrCast(c.wglGetProcAddress("glSampleMaski"));
        }

        if (version >= 330) {
            gl.bindFragDataLocationIndexed = @ptrCast(c.wglGetProcAddress("glBindFragDataLocationIndexed"));
            gl.getFragDataIndex = @ptrCast(c.wglGetProcAddress("glGetFragDataIndex"));
            gl.genSamplers = @ptrCast(c.wglGetProcAddress("glGenSamplers"));
            gl.deleteSamplers = @ptrCast(c.wglGetProcAddress("glDeleteSamplers"));
            gl.isSampler = @ptrCast(c.wglGetProcAddress("glIsSampler"));
            gl.bindSampler = @ptrCast(c.wglGetProcAddress("glBindSampler"));
            gl.samplerParameteri = @ptrCast(c.wglGetProcAddress("glSamplerParameteri"));
            gl.samplerParameteriv = @ptrCast(c.wglGetProcAddress("glSamplerParameteriv"));
            gl.samplerParameterf = @ptrCast(c.wglGetProcAddress("glSamplerParameterf"));
            gl.samplerParameterfv = @ptrCast(c.wglGetProcAddress("glSamplerParameterfv"));
            gl.samplerParameterIiv = @ptrCast(c.wglGetProcAddress("glSamplerParameterIiv"));
            gl.samplerParameterIuiv = @ptrCast(c.wglGetProcAddress("glSamplerParameterIuiv"));
            gl.getSamplerParameteriv = @ptrCast(c.wglGetProcAddress("glGetSamplerParameteriv"));
            gl.getSamplerParameterIiv = @ptrCast(c.wglGetProcAddress("glGetSamplerParameterIiv"));
            gl.getSamplerParameterfv = @ptrCast(c.wglGetProcAddress("glGetSamplerParameterfv"));
            gl.getSamplerParameterIuiv = @ptrCast(c.wglGetProcAddress("glGetSamplerParameterIuiv"));
            gl.queryCounter = @ptrCast(c.wglGetProcAddress("glQueryCounter"));
            gl.getQueryObjecti64v = @ptrCast(c.wglGetProcAddress("glGetQueryObjecti64v"));
            gl.getQueryObjectui64v = @ptrCast(c.wglGetProcAddress("glGetQueryObjectui64v"));
            gl.vertexAttribDivisor = @ptrCast(c.wglGetProcAddress("glVertexAttribDivisor"));
            gl.vertexAttribP1ui = @ptrCast(c.wglGetProcAddress("glVertexAttribP1ui"));
            gl.vertexAttribP1uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribP1uiv"));
            gl.vertexAttribP2ui = @ptrCast(c.wglGetProcAddress("glVertexAttribP2ui"));
            gl.vertexAttribP2uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribP2uiv"));
            gl.vertexAttribP3ui = @ptrCast(c.wglGetProcAddress("glVertexAttribP3ui"));
            gl.vertexAttribP3uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribP3uiv"));
            gl.vertexAttribP4ui = @ptrCast(c.wglGetProcAddress("glVertexAttribP4ui"));
            gl.vertexAttribP4uiv = @ptrCast(c.wglGetProcAddress("glVertexAttribP4uiv"));
        }

        if (version >= 400) {
            gl.minSampleShading = @ptrCast(c.wglGetProcAddress("glMinSampleShading"));
            gl.blendEquationi = @ptrCast(c.wglGetProcAddress("glBlendEquationi"));
            gl.blendEquationSeparatei = @ptrCast(c.wglGetProcAddress("glBlendEquationSeparatei"));
            gl.blendFunci = @ptrCast(c.wglGetProcAddress("glBlendFunci"));
            gl.blendFuncSeparatei = @ptrCast(c.wglGetProcAddress("glBlendFuncSeparatei"));
            gl.drawArraysIndirect = @ptrCast(c.wglGetProcAddress("glDrawArraysIndirect"));
            gl.drawElementsIndirect = @ptrCast(c.wglGetProcAddress("glDrawElementsIndirect"));
            gl.uniform1d = @ptrCast(c.wglGetProcAddress("glUniform1d"));
            gl.uniform2d = @ptrCast(c.wglGetProcAddress("glUniform2d"));
            gl.uniform3d = @ptrCast(c.wglGetProcAddress("glUniform3d"));
            gl.uniform4d = @ptrCast(c.wglGetProcAddress("glUniform4d"));
            gl.uniform1dv = @ptrCast(c.wglGetProcAddress("glUniform1dv"));
            gl.uniform2dv = @ptrCast(c.wglGetProcAddress("glUniform2dv"));
            gl.uniform3dv = @ptrCast(c.wglGetProcAddress("glUniform3dv"));
            gl.uniform4dv = @ptrCast(c.wglGetProcAddress("glUniform4dv"));
            gl.uniformMatrix2dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2dv"));
            gl.uniformMatrix3dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3dv"));
            gl.uniformMatrix4dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4dv"));
            gl.uniformMatrix2x3dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2x3dv"));
            gl.uniformMatrix2x4dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix2x4dv"));
            gl.uniformMatrix3x2dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3x2dv"));
            gl.uniformMatrix3x4dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix3x4dv"));
            gl.uniformMatrix4x2dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4x2dv"));
            gl.uniformMatrix4x3dv = @ptrCast(c.wglGetProcAddress("glUniformMatrix4x3dv"));
            gl.getUniformdv = @ptrCast(c.wglGetProcAddress("glGetUniformdv"));
            gl.getSubroutineUniformLocation = @ptrCast(c.wglGetProcAddress("glGetSubroutineUniformLocation"));
            gl.getSubroutineIndex = @ptrCast(c.wglGetProcAddress("glGetSubroutineIndex"));
            gl.getActiveSubroutineUniformiv = @ptrCast(c.wglGetProcAddress("glGetActiveSubroutineUniformiv"));
            gl.getActiveSubroutineUniformName = @ptrCast(c.wglGetProcAddress("glGetActiveSubroutineUniformName"));
            gl.getActiveSubroutineName = @ptrCast(c.wglGetProcAddress("glGetActiveSubroutineName"));
            gl.uniformSubroutinesuiv = @ptrCast(c.wglGetProcAddress("glUniformSubroutinesuiv"));
            gl.getUniformSubroutineuiv = @ptrCast(c.wglGetProcAddress("glGetUniformSubroutineuiv"));
            gl.getProgramStageiv = @ptrCast(c.wglGetProcAddress("glGetProgramStageiv"));
            gl.patchParameteri = @ptrCast(c.wglGetProcAddress("glPatchParameteri"));
            gl.patchParameterfv = @ptrCast(c.wglGetProcAddress("glPatchParameterfv"));
            gl.bindTransformFeedback = @ptrCast(c.wglGetProcAddress("glBindTransformFeedback"));
            gl.deleteTransformFeedbacks = @ptrCast(c.wglGetProcAddress("glDeleteTransformFeedbacks"));
            gl.genTransformFeedbacks = @ptrCast(c.wglGetProcAddress("glGenTransformFeedbacks"));
            gl.isTransformFeedback = @ptrCast(c.wglGetProcAddress("glIsTransformFeedback"));
            gl.pauseTransformFeedback = @ptrCast(c.wglGetProcAddress("glPauseTransformFeedback"));
            gl.resumeTransformFeedback = @ptrCast(c.wglGetProcAddress("glResumeTransformFeedback"));
            gl.drawTransformFeedback = @ptrCast(c.wglGetProcAddress("glDrawTransformFeedback"));
            gl.drawTransformFeedbackStream = @ptrCast(c.wglGetProcAddress("glDrawTransformFeedbackStream"));
            gl.beginQueryIndexed = @ptrCast(c.wglGetProcAddress("glBeginQueryIndexed"));
            gl.endQueryIndexed = @ptrCast(c.wglGetProcAddress("glEndQueryIndexed"));
            gl.getQueryIndexediv = @ptrCast(c.wglGetProcAddress("glGetQueryIndexediv"));
        }

        if (version >= 410) {
            gl.releaseShaderCompiler = @ptrCast(c.wglGetProcAddress("glReleaseShaderCompiler"));
            gl.shaderBinary = @ptrCast(c.wglGetProcAddress("glShaderBinary"));
            gl.getShaderPrecisionFormat = @ptrCast(c.wglGetProcAddress("glGetShaderPrecisionFormat"));
            gl.depthRangef = @ptrCast(c.wglGetProcAddress("glDepthRangef"));
            gl.clearDepthf = @ptrCast(c.wglGetProcAddress("glClearDepthf"));
            gl.getProgramBinary = @ptrCast(c.wglGetProcAddress("glGetProgramBinary"));
            gl.programBinary = @ptrCast(c.wglGetProcAddress("glProgramBinary"));
            gl.programParameteri = @ptrCast(c.wglGetProcAddress("glProgramParameteri"));
            gl.useProgramStages = @ptrCast(c.wglGetProcAddress("glUseProgramStages"));
            gl.activeShaderProgram = @ptrCast(c.wglGetProcAddress("glActiveShaderProgram"));
            gl.createShaderProgramv = @ptrCast(c.wglGetProcAddress("glCreateShaderProgramv"));
            gl.bindProgramPipeline = @ptrCast(c.wglGetProcAddress("glBindProgramPipeline"));
            gl.deleteProgramPipelines = @ptrCast(c.wglGetProcAddress("glDeleteProgramPipelines"));
            gl.genProgramPipelines = @ptrCast(c.wglGetProcAddress("glGenProgramPipelines"));
            gl.isProgramPipeline = @ptrCast(c.wglGetProcAddress("glIsProgramPipeline"));
            gl.getProgramPipelineiv = @ptrCast(c.wglGetProcAddress("glGetProgramPipelineiv"));
            gl.programUniform1i = @ptrCast(c.wglGetProcAddress("glProgramUniform1i"));
            gl.programUniform1iv = @ptrCast(c.wglGetProcAddress("glProgramUniform1iv"));
            gl.programUniform1f = @ptrCast(c.wglGetProcAddress("glProgramUniform1f"));
            gl.programUniform1fv = @ptrCast(c.wglGetProcAddress("glProgramUniform1fv"));
            gl.programUniform1d = @ptrCast(c.wglGetProcAddress("glProgramUniform1d"));
            gl.programUniform1dv = @ptrCast(c.wglGetProcAddress("glProgramUniform1dv"));
            gl.programUniform1ui = @ptrCast(c.wglGetProcAddress("glProgramUniform1ui"));
            gl.programUniform1uiv = @ptrCast(c.wglGetProcAddress("glProgramUniform1uiv"));
            gl.programUniform2i = @ptrCast(c.wglGetProcAddress("glProgramUniform2i"));
            gl.programUniform2iv = @ptrCast(c.wglGetProcAddress("glProgramUniform2iv"));
            gl.programUniform2f = @ptrCast(c.wglGetProcAddress("glProgramUniform2f"));
            gl.programUniform2fv = @ptrCast(c.wglGetProcAddress("glProgramUniform2fv"));
            gl.programUniform2d = @ptrCast(c.wglGetProcAddress("glProgramUniform2d"));
            gl.programUniform2dv = @ptrCast(c.wglGetProcAddress("glProgramUniform2dv"));
            gl.programUniform2ui = @ptrCast(c.wglGetProcAddress("glProgramUniform2ui"));
            gl.programUniform2uiv = @ptrCast(c.wglGetProcAddress("glProgramUniform2uiv"));
            gl.programUniform3i = @ptrCast(c.wglGetProcAddress("glProgramUniform3i"));
            gl.programUniform3iv = @ptrCast(c.wglGetProcAddress("glProgramUniform3iv"));
            gl.programUniform3f = @ptrCast(c.wglGetProcAddress("glProgramUniform3f"));
            gl.programUniform3fv = @ptrCast(c.wglGetProcAddress("glProgramUniform3fv"));
            gl.programUniform3d = @ptrCast(c.wglGetProcAddress("glProgramUniform3d"));
            gl.programUniform3dv = @ptrCast(c.wglGetProcAddress("glProgramUniform3dv"));
            gl.programUniform3ui = @ptrCast(c.wglGetProcAddress("glProgramUniform3ui"));
            gl.programUniform3uiv = @ptrCast(c.wglGetProcAddress("glProgramUniform3uiv"));
            gl.programUniform4i = @ptrCast(c.wglGetProcAddress("glProgramUniform4i"));
            gl.programUniform4iv = @ptrCast(c.wglGetProcAddress("glProgramUniform4iv"));
            gl.programUniform4f = @ptrCast(c.wglGetProcAddress("glProgramUniform4f"));
            gl.programUniform4fv = @ptrCast(c.wglGetProcAddress("glProgramUniform4fv"));
            gl.programUniform4d = @ptrCast(c.wglGetProcAddress("glProgramUniform4d"));
            gl.programUniform4dv = @ptrCast(c.wglGetProcAddress("glProgramUniform4dv"));
            gl.programUniform4ui = @ptrCast(c.wglGetProcAddress("glProgramUniform4ui"));
            gl.programUniform4uiv = @ptrCast(c.wglGetProcAddress("glProgramUniform4uiv"));
            gl.programUniformMatrix2fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2fv"));
            gl.programUniformMatrix3fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3fv"));
            gl.programUniformMatrix4fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4fv"));
            gl.programUniformMatrix2dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2dv"));
            gl.programUniformMatrix3dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3dv"));
            gl.programUniformMatrix4dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4dv"));
            gl.programUniformMatrix2x3fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2x3fv"));
            gl.programUniformMatrix3x2fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3x2fv"));
            gl.programUniformMatrix2x4fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2x4fv"));
            gl.programUniformMatrix4x2fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4x2fv"));
            gl.programUniformMatrix3x4fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3x4fv"));
            gl.programUniformMatrix4x3fv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4x3fv"));
            gl.programUniformMatrix2x3dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2x3dv"));
            gl.programUniformMatrix3x2dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3x2dv"));
            gl.programUniformMatrix2x4dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix2x4dv"));
            gl.programUniformMatrix4x2dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4x2dv"));
            gl.programUniformMatrix3x4dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix3x4dv"));
            gl.programUniformMatrix4x3dv = @ptrCast(c.wglGetProcAddress("glProgramUniformMatrix4x3dv"));
            gl.validateProgramPipeline = @ptrCast(c.wglGetProcAddress("glValidateProgramPipeline"));
            gl.getProgramPipelineInfoLog = @ptrCast(c.wglGetProcAddress("glGetProgramPipelineInfoLog"));
            gl.vertexAttribL1d = @ptrCast(c.wglGetProcAddress("glVertexAttribL1d"));
            gl.vertexAttribL2d = @ptrCast(c.wglGetProcAddress("glVertexAttribL2d"));
            gl.vertexAttribL3d = @ptrCast(c.wglGetProcAddress("glVertexAttribL3d"));
            gl.vertexAttribL4d = @ptrCast(c.wglGetProcAddress("glVertexAttribL4d"));
            gl.vertexAttribL1dv = @ptrCast(c.wglGetProcAddress("glVertexAttribL1dv"));
            gl.vertexAttribL2dv = @ptrCast(c.wglGetProcAddress("glVertexAttribL2dv"));
            gl.vertexAttribL3dv = @ptrCast(c.wglGetProcAddress("glVertexAttribL3dv"));
            gl.vertexAttribL4dv = @ptrCast(c.wglGetProcAddress("glVertexAttribL4dv"));
            gl.vertexAttribLPointer = @ptrCast(c.wglGetProcAddress("glVertexAttribLPointer"));
            gl.getVertexAttribLdv = @ptrCast(c.wglGetProcAddress("glGetVertexAttribLdv"));
            gl.viewportArrayv = @ptrCast(c.wglGetProcAddress("glViewportArrayv"));
            gl.viewportIndexedf = @ptrCast(c.wglGetProcAddress("glViewportIndexedf"));
            gl.viewportIndexedfv = @ptrCast(c.wglGetProcAddress("glViewportIndexedfv"));
            gl.scissorArrayv = @ptrCast(c.wglGetProcAddress("glScissorArrayv"));
            gl.scissorIndexed = @ptrCast(c.wglGetProcAddress("glScissorIndexed"));
            gl.scissorIndexedv = @ptrCast(c.wglGetProcAddress("glScissorIndexedv"));
            gl.depthRangeArrayv = @ptrCast(c.wglGetProcAddress("glDepthRangeArrayv"));
            gl.depthRangeIndexed = @ptrCast(c.wglGetProcAddress("glDepthRangeIndexed"));
            gl.getFloati_v = @ptrCast(c.wglGetProcAddress("glGetFloati_v"));
            gl.getDoublei_v = @ptrCast(c.wglGetProcAddress("glGetDoublei_v"));
        }

        if (version >= 420) {
            gl.drawArraysInstancedBaseInstance = @ptrCast(c.wglGetProcAddress("glDrawArraysInstancedBaseInstance"));
            gl.drawElementsInstancedBaseInstance = @ptrCast(c.wglGetProcAddress("glDrawElementsInstancedBaseInstance"));
            gl.drawElementsInstancedBaseVertexBaseInstance = @ptrCast(c.wglGetProcAddress("glDrawElementsInstancedBaseVertexBaseInstance"));
            gl.getInternalformativ = @ptrCast(c.wglGetProcAddress("glGetInternalformativ"));
            gl.getActiveAtomicCounterBufferiv = @ptrCast(c.wglGetProcAddress("glGetActiveAtomicCounterBufferiv"));
            gl.bindImageTexture = @ptrCast(c.wglGetProcAddress("glBindImageTexture"));
            gl.memoryBarrier = @ptrCast(c.wglGetProcAddress("glMemoryBarrier"));
            gl.texStorage1D = @ptrCast(c.wglGetProcAddress("glTexStorage1D"));
            gl.texStorage2D = @ptrCast(c.wglGetProcAddress("glTexStorage2D"));
            gl.texStorage3D = @ptrCast(c.wglGetProcAddress("glTexStorage3D"));
            gl.drawTransformFeedbackInstanced = @ptrCast(c.wglGetProcAddress("glDrawTransformFeedbackInstanced"));
            gl.drawTransformFeedbackStreamInstanced = @ptrCast(c.wglGetProcAddress("glDrawTransformFeedbackStreamInstanced"));
        }

        if (version >= 430) {
            gl.clearBufferData = @ptrCast(c.wglGetProcAddress("glClearBufferData"));
            gl.clearBufferSubData = @ptrCast(c.wglGetProcAddress("glClearBufferSubData"));
            gl.dispatchCompute = @ptrCast(c.wglGetProcAddress("glDispatchCompute"));
            gl.dispatchComputeIndirect = @ptrCast(c.wglGetProcAddress("glDispatchComputeIndirect"));
            gl.copyImageSubData = @ptrCast(c.wglGetProcAddress("glCopyImageSubData"));
            gl.framebufferParameteri = @ptrCast(c.wglGetProcAddress("glFramebufferParameteri"));
            gl.getFramebufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetFramebufferParameteriv"));
            gl.getInternalformati64v = @ptrCast(c.wglGetProcAddress("glGetInternalformati64v"));
            gl.invalidateTexSubImage = @ptrCast(c.wglGetProcAddress("glInvalidateTexSubImage"));
            gl.invalidateTexImage = @ptrCast(c.wglGetProcAddress("glInvalidateTexImage"));
            gl.invalidateBufferSubData = @ptrCast(c.wglGetProcAddress("glInvalidateBufferSubData"));
            gl.invalidateBufferData = @ptrCast(c.wglGetProcAddress("glInvalidateBufferData"));
            gl.invalidateFramebuffer = @ptrCast(c.wglGetProcAddress("glInvalidateFramebuffer"));
            gl.invalidateSubFramebuffer = @ptrCast(c.wglGetProcAddress("glInvalidateSubFramebuffer"));
            gl.multiDrawArraysIndirect = @ptrCast(c.wglGetProcAddress("glMultiDrawArraysIndirect"));
            gl.multiDrawElementsIndirect = @ptrCast(c.wglGetProcAddress("glMultiDrawElementsIndirect"));
            gl.getProgramInterfaceiv = @ptrCast(c.wglGetProcAddress("glGetProgramInterfaceiv"));
            gl.getProgramResourceIndex = @ptrCast(c.wglGetProcAddress("glGetProgramResourceIndex"));
            gl.getProgramResourceName = @ptrCast(c.wglGetProcAddress("glGetProgramResourceName"));
            gl.getProgramResourceiv = @ptrCast(c.wglGetProcAddress("glGetProgramResourceiv"));
            gl.getProgramResourceLocation = @ptrCast(c.wglGetProcAddress("glGetProgramResourceLocation"));
            gl.getProgramResourceLocationIndex = @ptrCast(c.wglGetProcAddress("glGetProgramResourceLocationIndex"));
            gl.shaderStorageBlockBinding = @ptrCast(c.wglGetProcAddress("glShaderStorageBlockBinding"));
            gl.texBufferRange = @ptrCast(c.wglGetProcAddress("glTexBufferRange"));
            gl.texStorage2DMultisample = @ptrCast(c.wglGetProcAddress("glTexStorage2DMultisample"));
            gl.texStorage3DMultisample = @ptrCast(c.wglGetProcAddress("glTexStorage3DMultisample"));
            gl.textureView = @ptrCast(c.wglGetProcAddress("glTextureView"));
            gl.bindVertexBuffer = @ptrCast(c.wglGetProcAddress("glBindVertexBuffer"));
            gl.vertexAttribFormat = @ptrCast(c.wglGetProcAddress("glVertexAttribFormat"));
            gl.vertexAttribIFormat = @ptrCast(c.wglGetProcAddress("glVertexAttribIFormat"));
            gl.vertexAttribLFormat = @ptrCast(c.wglGetProcAddress("glVertexAttribLFormat"));
            gl.vertexAttribBinding = @ptrCast(c.wglGetProcAddress("glVertexAttribBinding"));
            gl.vertexBindingDivisor = @ptrCast(c.wglGetProcAddress("glVertexBindingDivisor"));
            gl.debugMessageControl = @ptrCast(c.wglGetProcAddress("glDebugMessageControl"));
            gl.debugMessageInsert = @ptrCast(c.wglGetProcAddress("glDebugMessageInsert"));
            gl.debugMessageCallback = @ptrCast(c.wglGetProcAddress("glDebugMessageCallback"));
            gl.getDebugMessageLog = @ptrCast(c.wglGetProcAddress("glGetDebugMessageLog"));
            gl.pushDebugGroup = @ptrCast(c.wglGetProcAddress("glPushDebugGroup"));
            gl.popDebugGroup = @ptrCast(c.wglGetProcAddress("glPopDebugGroup"));
            gl.objectLabel = @ptrCast(c.wglGetProcAddress("glObjectLabel"));
            gl.getObjectLabel = @ptrCast(c.wglGetProcAddress("glGetObjectLabel"));
            gl.objectPtrLabel = @ptrCast(c.wglGetProcAddress("glObjectPtrLabel"));
            gl.getObjectPtrLabel = @ptrCast(c.wglGetProcAddress("glGetObjectPtrLabel"));
        }

        if (version >= 440) {
            gl.bufferStorage = @ptrCast(c.wglGetProcAddress("glBufferStorage"));
            gl.clearTexImage = @ptrCast(c.wglGetProcAddress("glClearTexImage"));
            gl.clearTexSubImage = @ptrCast(c.wglGetProcAddress("glClearTexSubImage"));
            gl.bindBuffersBase = @ptrCast(c.wglGetProcAddress("glBindBuffersBase"));
            gl.bindBuffersRange = @ptrCast(c.wglGetProcAddress("glBindBuffersRange"));
            gl.bindTextures = @ptrCast(c.wglGetProcAddress("glBindTextures"));
            gl.bindSamplers = @ptrCast(c.wglGetProcAddress("glBindSamplers"));
            gl.bindImageTextures = @ptrCast(c.wglGetProcAddress("glBindImageTextures"));
            gl.bindVertexBuffers = @ptrCast(c.wglGetProcAddress("glBindVertexBuffers"));
        }

        if (version >= 450) {
            gl.clipControl = @ptrCast(c.wglGetProcAddress("glClipControl"));
            gl.createTransformFeedbacks = @ptrCast(c.wglGetProcAddress("glCreateTransformFeedbacks"));
            gl.transformFeedbackBufferBase = @ptrCast(c.wglGetProcAddress("glTransformFeedbackBufferBase"));
            gl.transformFeedbackBufferRange = @ptrCast(c.wglGetProcAddress("glTransformFeedbackBufferRange"));
            gl.getTransformFeedbackiv = @ptrCast(c.wglGetProcAddress("glGetTransformFeedbackiv"));
            gl.getTransformFeedbacki_v = @ptrCast(c.wglGetProcAddress("glGetTransformFeedbacki_v"));
            gl.getTransformFeedbacki64_v = @ptrCast(c.wglGetProcAddress("glGetTransformFeedbacki64_v"));
            gl.createBuffers = @ptrCast(c.wglGetProcAddress("glCreateBuffers"));
            gl.namedBufferStorage = @ptrCast(c.wglGetProcAddress("glNamedBufferStorage"));
            gl.namedBufferData = @ptrCast(c.wglGetProcAddress("glNamedBufferData"));
            gl.namedBufferSubData = @ptrCast(c.wglGetProcAddress("glNamedBufferSubData"));
            gl.copyNamedBufferSubData = @ptrCast(c.wglGetProcAddress("glCopyNamedBufferSubData"));
            gl.clearNamedBufferData = @ptrCast(c.wglGetProcAddress("glClearNamedBufferData"));
            gl.clearNamedBufferSubData = @ptrCast(c.wglGetProcAddress("glClearNamedBufferSubData"));
            gl.mapNamedBuffer = @ptrCast(c.wglGetProcAddress("glMapNamedBuffer"));
            gl.mapNamedBufferRange = @ptrCast(c.wglGetProcAddress("glMapNamedBufferRange"));
            gl.unmapNamedBuffer = @ptrCast(c.wglGetProcAddress("glUnmapNamedBuffer"));
            gl.flushMappedNamedBufferRange = @ptrCast(c.wglGetProcAddress("glFlushMappedNamedBufferRange"));
            gl.getNamedBufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetNamedBufferParameteriv"));
            gl.getNamedBufferParameteri64v = @ptrCast(c.wglGetProcAddress("glGetNamedBufferParameteri64v"));
            gl.getNamedBufferPointerv = @ptrCast(c.wglGetProcAddress("glGetNamedBufferPointerv"));
            gl.getNamedBufferSubData = @ptrCast(c.wglGetProcAddress("glGetNamedBufferSubData"));
            gl.createFramebuffers = @ptrCast(c.wglGetProcAddress("glCreateFramebuffers"));
            gl.namedFramebufferRenderbuffer = @ptrCast(c.wglGetProcAddress("glNamedFramebufferRenderbuffer"));
            gl.namedFramebufferParameteri = @ptrCast(c.wglGetProcAddress("glNamedFramebufferParameteri"));
            gl.namedFramebufferTexture = @ptrCast(c.wglGetProcAddress("glNamedFramebufferTexture"));
            gl.namedFramebufferTextureLayer = @ptrCast(c.wglGetProcAddress("glNamedFramebufferTextureLayer"));
            gl.namedFramebufferDrawBuffer = @ptrCast(c.wglGetProcAddress("glNamedFramebufferDrawBuffer"));
            gl.namedFramebufferDrawBuffers = @ptrCast(c.wglGetProcAddress("glNamedFramebufferDrawBuffers"));
            gl.namedFramebufferReadBuffer = @ptrCast(c.wglGetProcAddress("glNamedFramebufferReadBuffer"));
            gl.invalidateNamedFramebufferData = @ptrCast(c.wglGetProcAddress("glInvalidateNamedFramebufferData"));
            gl.invalidateNamedFramebufferSubData = @ptrCast(c.wglGetProcAddress("glInvalidateNamedFramebufferSubData"));
            gl.clearNamedFramebufferiv = @ptrCast(c.wglGetProcAddress("glClearNamedFramebufferiv"));
            gl.clearNamedFramebufferuiv = @ptrCast(c.wglGetProcAddress("glClearNamedFramebufferuiv"));
            gl.clearNamedFramebufferfv = @ptrCast(c.wglGetProcAddress("glClearNamedFramebufferfv"));
            gl.clearNamedFramebufferfi = @ptrCast(c.wglGetProcAddress("glClearNamedFramebufferfi"));
            gl.blitNamedFramebuffer = @ptrCast(c.wglGetProcAddress("glBlitNamedFramebuffer"));
            gl.checkNamedFramebufferStatus = @ptrCast(c.wglGetProcAddress("glCheckNamedFramebufferStatus"));
            gl.getNamedFramebufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetNamedFramebufferParameteriv"));
            gl.getNamedFramebufferAttachmentParameteriv = @ptrCast(c.wglGetProcAddress("glGetNamedFramebufferAttachmentParameteriv"));
            gl.createRenderbuffers = @ptrCast(c.wglGetProcAddress("glCreateRenderbuffers"));
            gl.namedRenderbufferStorage = @ptrCast(c.wglGetProcAddress("glNamedRenderbufferStorage"));
            gl.namedRenderbufferStorageMultisample = @ptrCast(c.wglGetProcAddress("glNamedRenderbufferStorageMultisample"));
            gl.getNamedRenderbufferParameteriv = @ptrCast(c.wglGetProcAddress("glGetNamedRenderbufferParameteriv"));
            gl.createTextures = @ptrCast(c.wglGetProcAddress("glCreateTextures"));
            gl.textureBuffer = @ptrCast(c.wglGetProcAddress("glTextureBuffer"));
            gl.textureBufferRange = @ptrCast(c.wglGetProcAddress("glTextureBufferRange"));
            gl.textureStorage1D = @ptrCast(c.wglGetProcAddress("glTextureStorage1D"));
            gl.textureStorage2D = @ptrCast(c.wglGetProcAddress("glTextureStorage2D"));
            gl.textureStorage3D = @ptrCast(c.wglGetProcAddress("glTextureStorage3D"));
            gl.textureStorage2DMultisample = @ptrCast(c.wglGetProcAddress("glTextureStorage2DMultisample"));
            gl.textureStorage3DMultisample = @ptrCast(c.wglGetProcAddress("glTextureStorage3DMultisample"));
            gl.textureSubImage1D = @ptrCast(c.wglGetProcAddress("glTextureSubImage1D"));
            gl.textureSubImage2D = @ptrCast(c.wglGetProcAddress("glTextureSubImage2D"));
            gl.textureSubImage3D = @ptrCast(c.wglGetProcAddress("glTextureSubImage3D"));
            gl.compressedTextureSubImage1D = @ptrCast(c.wglGetProcAddress("glCompressedTextureSubImage1D"));
            gl.compressedTextureSubImage2D = @ptrCast(c.wglGetProcAddress("glCompressedTextureSubImage2D"));
            gl.compressedTextureSubImage3D = @ptrCast(c.wglGetProcAddress("glCompressedTextureSubImage3D"));
            gl.copyTextureSubImage1D = @ptrCast(c.wglGetProcAddress("glCopyTextureSubImage1D"));
            gl.copyTextureSubImage2D = @ptrCast(c.wglGetProcAddress("glCopyTextureSubImage2D"));
            gl.copyTextureSubImage3D = @ptrCast(c.wglGetProcAddress("glCopyTextureSubImage3D"));
            gl.textureParameterf = @ptrCast(c.wglGetProcAddress("glTextureParameterf"));
            gl.textureParameterfv = @ptrCast(c.wglGetProcAddress("glTextureParameterfv"));
            gl.textureParameteri = @ptrCast(c.wglGetProcAddress("glTextureParameteri"));
            gl.textureParameterIiv = @ptrCast(c.wglGetProcAddress("glTextureParameterIiv"));
            gl.textureParameterIuiv = @ptrCast(c.wglGetProcAddress("glTextureParameterIuiv"));
            gl.textureParameteriv = @ptrCast(c.wglGetProcAddress("glTextureParameteriv"));
            gl.generateTextureMipmap = @ptrCast(c.wglGetProcAddress("glGenerateTextureMipmap"));
            gl.bindTextureUnit = @ptrCast(c.wglGetProcAddress("glBindTextureUnit"));
            gl.getTextureImage = @ptrCast(c.wglGetProcAddress("glGetTextureImage"));
            gl.getCompressedTextureImage = @ptrCast(c.wglGetProcAddress("glGetCompressedTextureImage"));
            gl.getTextureLevelParameterfv = @ptrCast(c.wglGetProcAddress("glGetTextureLevelParameterfv"));
            gl.getTextureLevelParameteriv = @ptrCast(c.wglGetProcAddress("glGetTextureLevelParameteriv"));
            gl.getTextureParameterfv = @ptrCast(c.wglGetProcAddress("glGetTextureParameterfv"));
            gl.getTextureParameterIiv = @ptrCast(c.wglGetProcAddress("glGetTextureParameterIiv"));
            gl.getTextureParameterIuiv = @ptrCast(c.wglGetProcAddress("glGetTextureParameterIuiv"));
            gl.getTextureParameteriv = @ptrCast(c.wglGetProcAddress("glGetTextureParameteriv"));
            gl.createVertexArrays = @ptrCast(c.wglGetProcAddress("glCreateVertexArrays"));
            gl.disableVertexArrayAttrib = @ptrCast(c.wglGetProcAddress("glDisableVertexArrayAttrib"));
            gl.enableVertexArrayAttrib = @ptrCast(c.wglGetProcAddress("glEnableVertexArrayAttrib"));
            gl.vertexArrayElementBuffer = @ptrCast(c.wglGetProcAddress("glVertexArrayElementBuffer"));
            gl.vertexArrayVertexBuffer = @ptrCast(c.wglGetProcAddress("glVertexArrayVertexBuffer"));
            gl.vertexArrayVertexBuffers = @ptrCast(c.wglGetProcAddress("glVertexArrayVertexBuffers"));
            gl.vertexArrayAttribBinding = @ptrCast(c.wglGetProcAddress("glVertexArrayAttribBinding"));
            gl.vertexArrayAttribFormat = @ptrCast(c.wglGetProcAddress("glVertexArrayAttribFormat"));
            gl.vertexArrayAttribIFormat = @ptrCast(c.wglGetProcAddress("glVertexArrayAttribIFormat"));
            gl.vertexArrayAttribLFormat = @ptrCast(c.wglGetProcAddress("glVertexArrayAttribLFormat"));
            gl.vertexArrayBindingDivisor = @ptrCast(c.wglGetProcAddress("glVertexArrayBindingDivisor"));
            gl.getVertexArrayiv = @ptrCast(c.wglGetProcAddress("glGetVertexArrayiv"));
            gl.getVertexArrayIndexediv = @ptrCast(c.wglGetProcAddress("glGetVertexArrayIndexediv"));
            gl.getVertexArrayIndexed64iv = @ptrCast(c.wglGetProcAddress("glGetVertexArrayIndexed64iv"));
            gl.createSamplers = @ptrCast(c.wglGetProcAddress("glCreateSamplers"));
            gl.createProgramPipelines = @ptrCast(c.wglGetProcAddress("glCreateProgramPipelines"));
            gl.createQueries = @ptrCast(c.wglGetProcAddress("glCreateQueries"));
            gl.getQueryBufferObjecti64v = @ptrCast(c.wglGetProcAddress("glGetQueryBufferObjecti64v"));
            gl.getQueryBufferObjectiv = @ptrCast(c.wglGetProcAddress("glGetQueryBufferObjectiv"));
            gl.getQueryBufferObjectui64v = @ptrCast(c.wglGetProcAddress("glGetQueryBufferObjectui64v"));
            gl.getQueryBufferObjectuiv = @ptrCast(c.wglGetProcAddress("glGetQueryBufferObjectuiv"));
            gl.memoryBarrierByRegion = @ptrCast(c.wglGetProcAddress("glMemoryBarrierByRegion"));
            gl.getTextureSubImage = @ptrCast(c.wglGetProcAddress("glGetTextureSubImage"));
            gl.getCompressedTextureSubImage = @ptrCast(c.wglGetProcAddress("glGetCompressedTextureSubImage"));
            gl.getGraphicsResetStatus = @ptrCast(c.wglGetProcAddress("glGetGraphicsResetStatus"));
            gl.getnCompressedTexImage = @ptrCast(c.wglGetProcAddress("glGetnCompressedTexImage"));
            gl.getnTexImage = @ptrCast(c.wglGetProcAddress("glGetnTexImage"));
            gl.getnUniformdv = @ptrCast(c.wglGetProcAddress("glGetnUniformdv"));
            gl.getnUniformfv = @ptrCast(c.wglGetProcAddress("glGetnUniformfv"));
            gl.getnUniformiv = @ptrCast(c.wglGetProcAddress("glGetnUniformiv"));
            gl.getnUniformuiv = @ptrCast(c.wglGetProcAddress("glGetnUniformuiv"));
            gl.readnPixels = @ptrCast(c.wglGetProcAddress("glReadnPixels"));
            gl.textureBarrier = @ptrCast(c.wglGetProcAddress("glTextureBarrier"));
        }

        if (version >= 460) {
            gl.specializeShader = @ptrCast(c.wglGetProcAddress("glSpecializeShader"));
            gl.multiDrawArraysIndirectCount = @ptrCast(c.wglGetProcAddress("glMultiDrawArraysIndirectCount"));
            gl.multiDrawElementsIndirectCount = @ptrCast(c.wglGetProcAddress("glMultiDrawElementsIndirectCount"));
            gl.polygonOffsetClamp = @ptrCast(c.wglGetProcAddress("glPolygonOffsetClamp"));
        }
    }
};
