const c = @import("c");

pub const Error = error{
    CannotOpenResource,
    UnknownFileFormat,
    InvalidFileFormat,
    InvalidVersion,
    LowerModuleVersion,
    InvalidArgument,
    UnimplementedFeature,
    InvalidTable,
    InvalidOffset,
    ArrayTooLarge,
    MissingModule,
    MissingProperty,
    InvalidGlyphIndex,
    InvalidCharacterCode,
    InvalidGlyphFormat,
    CannotRenderGlyph,
    InvalidOutline,
    InvalidComposite,
    TooManyHints,
    InvalidPixelSize,
    InvalidHandle,
    InvalidLibraryHandle,
    InvalidDriverHandle,
    InvalidFaceHandle,
    InvalidSizeHandle,
    InvalidSlotHandle,
    InvalidCharMapHandle,
    InvalidCacheHandle,
    InvalidStreamHandle,
    TooManyDrivers,
    TooManyExtensions,
    OutOfMemory,
    UnlistedObject,
    CannotOpenStream,
    InvalidStreamSeek,
    InvalidStreamSkip,
    InvalidStreamRead,
    InvalidStreamOperation,
    InvalidFrameOperation,
    NestedFrameAccess,
    InvalidFrameRead,
    RasterUninitialized,
    RasterCorrupted,
    RasterOverflow,
    RasterNegativeHeight,
    TooManyCaches,
    InvalidOpcode,
    TooFewArguments,
    StackOverflow,
    CodeOverflow,
    BadArgument,
    DivideByZero,
    InvalidReference,
    DebugOpCode,
    ENDFInExecStream,
    NestedDEFS,
    InvalidCodeRange,
    ExecutionTooLong,
    TooManyFunctionDefs,
    TooManyInstructionDefs,
    TableMissing,
    HorizHeaderMissing,
    LocationsMissing,
    NameTableMissing,
    CMapTableMissing,
    HmtxTableMissing,
    PostTableMissing,
    InvalidHorizMetrics,
    InvalidCharMapFormat,
    InvalidPPem,
    InvalidVertMetrics,
    CouldNotFindContext,
    InvalidPostTableFormat,
    InvalidPostTable,
    Syntax,
    StackUnderflow,
    Ignore,
    NoUnicodeGlyphName,
    MissingStartfontField,
    MissingFontField,
    MissingSizeField,
    MissingFontboundingboxField,
    MissingCharsField,
    MissingStartcharField,
    MissingEncodingField,
    MissingBbxField,
    BbxTooBig,
    CorruptedFontHeader,
    CorruptedFontGlyphs,
};

pub fn intToError(err: c_int) Error!void {
    return switch (err) {
        c.FT_Err_Ok => {},
        c.FT_Err_Cannot_Open_Resource => Error.CannotOpenResource,
        c.FT_Err_Unknown_File_Format => Error.UnknownFileFormat,
        c.FT_Err_Invalid_File_Format => Error.InvalidFileFormat,
        c.FT_Err_Invalid_Version => Error.InvalidVersion,
        c.FT_Err_Lower_Module_Version => Error.LowerModuleVersion,
        c.FT_Err_Invalid_Argument => Error.InvalidArgument,
        c.FT_Err_Unimplemented_Feature => Error.UnimplementedFeature,
        c.FT_Err_Invalid_Table => Error.InvalidTable,
        c.FT_Err_Invalid_Offset => Error.InvalidOffset,
        c.FT_Err_Array_Too_Large => Error.ArrayTooLarge,
        c.FT_Err_Missing_Module => Error.MissingModule,
        c.FT_Err_Missing_Property => Error.MissingProperty,
        c.FT_Err_Invalid_Glyph_Index => Error.InvalidGlyphIndex,
        c.FT_Err_Invalid_Character_Code => Error.InvalidCharacterCode,
        c.FT_Err_Invalid_Glyph_Format => Error.InvalidGlyphFormat,
        c.FT_Err_Cannot_Render_Glyph => Error.CannotRenderGlyph,
        c.FT_Err_Invalid_Outline => Error.InvalidOutline,
        c.FT_Err_Invalid_Composite => Error.InvalidComposite,
        c.FT_Err_Too_Many_Hints => Error.TooManyHints,
        c.FT_Err_Invalid_Pixel_Size => Error.InvalidPixelSize,
        c.FT_Err_Invalid_Handle => Error.InvalidHandle,
        c.FT_Err_Invalid_Library_Handle => Error.InvalidLibraryHandle,
        c.FT_Err_Invalid_Driver_Handle => Error.InvalidDriverHandle,
        c.FT_Err_Invalid_Face_Handle => Error.InvalidFaceHandle,
        c.FT_Err_Invalid_Size_Handle => Error.InvalidSizeHandle,
        c.FT_Err_Invalid_Slot_Handle => Error.InvalidSlotHandle,
        c.FT_Err_Invalid_CharMap_Handle => Error.InvalidCharMapHandle,
        c.FT_Err_Invalid_Cache_Handle => Error.InvalidCacheHandle,
        c.FT_Err_Invalid_Stream_Handle => Error.InvalidStreamHandle,
        c.FT_Err_Too_Many_Drivers => Error.TooManyDrivers,
        c.FT_Err_Too_Many_Extensions => Error.TooManyExtensions,
        c.FT_Err_Out_Of_Memory => Error.OutOfMemory,
        c.FT_Err_Unlisted_Object => Error.UnlistedObject,
        c.FT_Err_Cannot_Open_Stream => Error.CannotOpenStream,
        c.FT_Err_Invalid_Stream_Seek => Error.InvalidStreamSeek,
        c.FT_Err_Invalid_Stream_Skip => Error.InvalidStreamSkip,
        c.FT_Err_Invalid_Stream_Read => Error.InvalidStreamRead,
        c.FT_Err_Invalid_Stream_Operation => Error.InvalidStreamOperation,
        c.FT_Err_Invalid_Frame_Operation => Error.InvalidFrameOperation,
        c.FT_Err_Nested_Frame_Access => Error.NestedFrameAccess,
        c.FT_Err_Invalid_Frame_Read => Error.InvalidFrameRead,
        c.FT_Err_Raster_Uninitialized => Error.RasterUninitialized,
        c.FT_Err_Raster_Corrupted => Error.RasterCorrupted,
        c.FT_Err_Raster_Overflow => Error.RasterOverflow,
        c.FT_Err_Raster_Negative_Height => Error.RasterNegativeHeight,
        c.FT_Err_Too_Many_Caches => Error.TooManyCaches,
        c.FT_Err_Invalid_Opcode => Error.InvalidOpcode,
        c.FT_Err_Too_Few_Arguments => Error.TooFewArguments,
        c.FT_Err_Stack_Overflow => Error.StackOverflow,
        c.FT_Err_Code_Overflow => Error.CodeOverflow,
        c.FT_Err_Bad_Argument => Error.BadArgument,
        c.FT_Err_Divide_By_Zero => Error.DivideByZero,
        c.FT_Err_Invalid_Reference => Error.InvalidReference,
        c.FT_Err_Debug_OpCode => Error.DebugOpCode,
        c.FT_Err_ENDF_In_Exec_Stream => Error.ENDFInExecStream,
        c.FT_Err_Nested_DEFS => Error.NestedDEFS,
        c.FT_Err_Invalid_CodeRange => Error.InvalidCodeRange,
        c.FT_Err_Execution_Too_Long => Error.ExecutionTooLong,
        c.FT_Err_Too_Many_Function_Defs => Error.TooManyFunctionDefs,
        c.FT_Err_Too_Many_Instruction_Defs => Error.TooManyInstructionDefs,
        c.FT_Err_Table_Missing => Error.TableMissing,
        c.FT_Err_Horiz_Header_Missing => Error.HorizHeaderMissing,
        c.FT_Err_Locations_Missing => Error.LocationsMissing,
        c.FT_Err_Name_Table_Missing => Error.NameTableMissing,
        c.FT_Err_CMap_Table_Missing => Error.CMapTableMissing,
        c.FT_Err_Hmtx_Table_Missing => Error.HmtxTableMissing,
        c.FT_Err_Post_Table_Missing => Error.PostTableMissing,
        c.FT_Err_Invalid_Horiz_Metrics => Error.InvalidHorizMetrics,
        c.FT_Err_Invalid_CharMap_Format => Error.InvalidCharMapFormat,
        c.FT_Err_Invalid_PPem => Error.InvalidPPem,
        c.FT_Err_Invalid_Vert_Metrics => Error.InvalidVertMetrics,
        c.FT_Err_Could_Not_Find_Context => Error.CouldNotFindContext,
        c.FT_Err_Invalid_Post_Table_Format => Error.InvalidPostTableFormat,
        c.FT_Err_Invalid_Post_Table => Error.InvalidPostTable,
        c.FT_Err_Syntax_Error => Error.Syntax,
        c.FT_Err_Stack_Underflow => Error.StackUnderflow,
        c.FT_Err_Ignore => Error.Ignore,
        c.FT_Err_No_Unicode_Glyph_Name => Error.NoUnicodeGlyphName,
        c.FT_Err_Missing_Startfont_Field => Error.MissingStartfontField,
        c.FT_Err_Missing_Font_Field => Error.MissingFontField,
        c.FT_Err_Missing_Size_Field => Error.MissingSizeField,
        c.FT_Err_Missing_Fontboundingbox_Field => Error.MissingFontboundingboxField,
        c.FT_Err_Missing_Chars_Field => Error.MissingCharsField,
        c.FT_Err_Missing_Startchar_Field => Error.MissingStartcharField,
        c.FT_Err_Missing_Encoding_Field => Error.MissingEncodingField,
        c.FT_Err_Missing_Bbx_Field => Error.MissingBbxField,
        c.FT_Err_Bbx_Too_Big => Error.BbxTooBig,
        c.FT_Err_Corrupted_Font_Header => Error.CorruptedFontHeader,
        c.FT_Err_Corrupted_Font_Glyphs => Error.CorruptedFontGlyphs,
        else => unreachable,
    };
}

pub fn errorToInt(err: Error) c_int {
    return switch (err) {
        Error.CannotOpenResource => c.FT_Err_Cannot_Open_Resource,
        Error.UnknownFileFormat => c.FT_Err_Unknown_File_Format,
        Error.InvalidFileFormat => c.FT_Err_Invalid_File_Format,
        Error.InvalidVersion => c.FT_Err_Invalid_Version,
        Error.LowerModuleVersion => c.FT_Err_Lower_Module_Version,
        Error.InvalidArgument => c.FT_Err_Invalid_Argument,
        Error.UnimplementedFeature => c.FT_Err_Unimplemented_Feature,
        Error.InvalidTable => c.FT_Err_Invalid_Table,
        Error.InvalidOffset => c.FT_Err_Invalid_Offset,
        Error.ArrayTooLarge => c.FT_Err_Array_Too_Large,
        Error.MissingModule => c.FT_Err_Missing_Module,
        Error.MissingProperty => c.FT_Err_Missing_Property,
        Error.InvalidGlyphIndex => c.FT_Err_Invalid_Glyph_Index,
        Error.InvalidCharacterCode => c.FT_Err_Invalid_Character_Code,
        Error.InvalidGlyphFormat => c.FT_Err_Invalid_Glyph_Format,
        Error.CannotRenderGlyph => c.FT_Err_Cannot_Render_Glyph,
        Error.InvalidOutline => c.FT_Err_Invalid_Outline,
        Error.InvalidComposite => c.FT_Err_Invalid_Composite,
        Error.TooManyHints => c.FT_Err_Too_Many_Hints,
        Error.InvalidPixelSize => c.FT_Err_Invalid_Pixel_Size,
        Error.InvalidHandle => c.FT_Err_Invalid_Handle,
        Error.InvalidLibraryHandle => c.FT_Err_Invalid_Library_Handle,
        Error.InvalidDriverHandle => c.FT_Err_Invalid_Driver_Handle,
        Error.InvalidFaceHandle => c.FT_Err_Invalid_Face_Handle,
        Error.InvalidSizeHandle => c.FT_Err_Invalid_Size_Handle,
        Error.InvalidSlotHandle => c.FT_Err_Invalid_Slot_Handle,
        Error.InvalidCharMapHandle => c.FT_Err_Invalid_CharMap_Handle,
        Error.InvalidCacheHandle => c.FT_Err_Invalid_Cache_Handle,
        Error.InvalidStreamHandle => c.FT_Err_Invalid_Stream_Handle,
        Error.TooManyDrivers => c.FT_Err_Too_Many_Drivers,
        Error.TooManyExtensions => c.FT_Err_Too_Many_Extensions,
        Error.OutOfMemory => c.FT_Err_Out_Of_Memory,
        Error.UnlistedObject => c.FT_Err_Unlisted_Object,
        Error.CannotOpenStream => c.FT_Err_Cannot_Open_Stream,
        Error.InvalidStreamSeek => c.FT_Err_Invalid_Stream_Seek,
        Error.InvalidStreamSkip => c.FT_Err_Invalid_Stream_Skip,
        Error.InvalidStreamRead => c.FT_Err_Invalid_Stream_Read,
        Error.InvalidStreamOperation => c.FT_Err_Invalid_Stream_Operation,
        Error.InvalidFrameOperation => c.FT_Err_Invalid_Frame_Operation,
        Error.NestedFrameAccess => c.FT_Err_Nested_Frame_Access,
        Error.InvalidFrameRead => c.FT_Err_Invalid_Frame_Read,
        Error.RasterUninitialized => c.FT_Err_Raster_Uninitialized,
        Error.RasterCorrupted => c.FT_Err_Raster_Corrupted,
        Error.RasterOverflow => c.FT_Err_Raster_Overflow,
        Error.RasterNegativeHeight => c.FT_Err_Raster_Negative_Height,
        Error.TooManyCaches => c.FT_Err_Too_Many_Caches,
        Error.InvalidOpcode => c.FT_Err_Invalid_Opcode,
        Error.TooFewArguments => c.FT_Err_Too_Few_Arguments,
        Error.StackOverflow => c.FT_Err_Stack_Overflow,
        Error.CodeOverflow => c.FT_Err_Code_Overflow,
        Error.BadArgument => c.FT_Err_Bad_Argument,
        Error.DivideByZero => c.FT_Err_Divide_By_Zero,
        Error.InvalidReference => c.FT_Err_Invalid_Reference,
        Error.DebugOpCode => c.FT_Err_Debug_OpCode,
        Error.ENDFInExecStream => c.FT_Err_ENDF_In_Exec_Stream,
        Error.NestedDEFS => c.FT_Err_Nested_DEFS,
        Error.InvalidCodeRange => c.FT_Err_Invalid_CodeRange,
        Error.ExecutionTooLong => c.FT_Err_Execution_Too_Long,
        Error.TooManyFunctionDefs => c.FT_Err_Too_Many_Function_Defs,
        Error.TooManyInstructionDefs => c.FT_Err_Too_Many_Instruction_Defs,
        Error.TableMissing => c.FT_Err_Table_Missing,
        Error.HorizHeaderMissing => c.FT_Err_Horiz_Header_Missing,
        Error.LocationsMissing => c.FT_Err_Locations_Missing,
        Error.NameTableMissing => c.FT_Err_Name_Table_Missing,
        Error.CMapTableMissing => c.FT_Err_CMap_Table_Missing,
        Error.HmtxTableMissing => c.FT_Err_Hmtx_Table_Missing,
        Error.PostTableMissing => c.FT_Err_Post_Table_Missing,
        Error.InvalidHorizMetrics => c.FT_Err_Invalid_Horiz_Metrics,
        Error.InvalidCharMapFormat => c.FT_Err_Invalid_CharMap_Format,
        Error.InvalidPPem => c.FT_Err_Invalid_PPem,
        Error.InvalidVertMetrics => c.FT_Err_Invalid_Vert_Metrics,
        Error.CouldNotFindContext => c.FT_Err_Could_Not_Find_Context,
        Error.InvalidPostTableFormat => c.FT_Err_Invalid_Post_Table_Format,
        Error.InvalidPostTable => c.FT_Err_Invalid_Post_Table,
        Error.Syntax => c.FT_Err_Syntax_Error,
        Error.StackUnderflow => c.FT_Err_Stack_Underflow,
        Error.Ignore => c.FT_Err_Ignore,
        Error.NoUnicodeGlyphName => c.FT_Err_No_Unicode_Glyph_Name,
        Error.MissingStartfontField => c.FT_Err_Missing_Startfont_Field,
        Error.MissingFontField => c.FT_Err_Missing_Font_Field,
        Error.MissingSizeField => c.FT_Err_Missing_Size_Field,
        Error.MissingFontboundingboxField => c.FT_Err_Missing_Fontboundingbox_Field,
        Error.MissingCharsField => c.FT_Err_Missing_Chars_Field,
        Error.MissingStartcharField => c.FT_Err_Missing_Startchar_Field,
        Error.MissingEncodingField => c.FT_Err_Missing_Encoding_Field,
        Error.MissingBbxField => c.FT_Err_Missing_Bbx_Field,
        Error.BbxTooBig => c.FT_Err_Bbx_Too_Big,
        Error.CorruptedFontHeader => c.FT_Err_Corrupted_Font_Header,
        Error.CorruptedFontGlyphs => c.FT_Err_Corrupted_Font_Glyphs,
    };
}

test "error convertion" {
    const expectError = @import("std").testing.expectError;

    try intToError(c.FT_Err_Ok);
    try expectError(Error.OutOfMemory, intToError(c.FT_Err_Out_Of_Memory));
}
