const std = @import("std");
const win32 = @import("../win32.zig");

pub fn pointFromLparam(lparam: win32.LPARAM) win32.POINT {
    return .{
        .x = @as(i16, @bitCast(win32.loword(lparam))),
        .y = @as(i16, @bitCast(win32.hiword(lparam))),
    };
}

pub const MessageNode = struct {
    tail_ref: *?*MessageNode,
    hwnd: win32.HWND,
    msg: u32,
    wparam: win32.WPARAM,
    lparam: win32.LPARAM,
    old_tail: ?*MessageNode,
    pub fn init(
        self: *MessageNode,
        tail_ref: *?*MessageNode,
        hwnd: win32.HWND,
        msg: u32,
        wparam: win32.WPARAM,
        lparam: win32.LPARAM,
    ) void {
        if (tail_ref.*) |old_tail| {
            std.debug.assert(old_tail.hwnd == hwnd);
        }
        self.* = .{
            .tail_ref = tail_ref,
            .hwnd = hwnd,
            .msg = msg,
            .wparam = wparam,
            .lparam = lparam,
            .old_tail = tail_ref.*,
        };
        tail_ref.* = self;
    }
    pub fn deinit(self: *MessageNode) void {
        std.debug.assert(self.tail_ref.* == self);
        self.tail_ref.* = self.old_tail;
    }
    pub fn fmtPath(self: *MessageNode) FmtPath {
        return .{ .node = self };
    }
};

fn writeMessageNodePath(
    writer: anytype,
    node: *MessageNode,
) !void {
    if (node.old_tail) |old_tail| {
        try writeMessageNodePath(writer, old_tail);
        try writer.writeAll(" > ");
    }
    try writer.print("{s}:{}", .{ msg_name(node.msg) orelse "?", node.msg });
    switch (node.msg) {
        win32.WM_CAPTURECHANGED => {
            try writer.print("({})", .{node.lparam});
        },
        win32.WM_SYSCOMMAND => {
            try writer.print("(type=0x{x})", .{0xfff0 & node.wparam});
        },
        else => {},
    }
}

const FmtPath = struct {
    node: *MessageNode,
    const Self = @This();
    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;
        try writeMessageNodePath(writer, self.node);
    }
};

pub fn msg_name(msg: u32) ?[]const u8 {
    return switch (msg) {
        0 => "WM_NULL",
        1 => "WM_CREATE",
        2 => "WM_DESTROY",
        3 => "WM_MOVE",
        5 => "WM_SIZE",
        6 => "WM_ACTIVATE",
        7 => "WM_SETFOCUS",
        8 => "WM_KILLFOCUS",
        10 => "WM_ENABLE",
        11 => "WM_SETREDRAW",
        12 => "WM_SETTEXT",
        13 => "WM_GETTEXT",
        14 => "WM_GETTEXTLENGTH",
        15 => "WM_PAINT",
        16 => "WM_CLOSE",
        17 => "WM_QUERYENDSESSION",
        18 => "WM_QUIT",
        19 => "WM_QUERYOPEN",
        20 => "WM_ERASEBKGND",
        21 => "WM_SYSCOLORCHANGE",
        22 => "WM_ENDSESSION",
        24 => "WM_SHOWWINDOW",
        25 => "WM_CTLCOLOR",
        26 => "WM_WININICHANGE",
        27 => "WM_DEVMODECHANGE",
        28 => "WM_ACTIVATEAPP",
        29 => "WM_FONTCHANGE",
        30 => "WM_TIMECHANGE",
        31 => "WM_CANCELMODE",
        32 => "WM_SETCURSOR",
        33 => "WM_MOUSEACTIVATE",
        34 => "WM_CHILDACTIVATE",
        35 => "WM_QUEUESYNC",
        36 => "WM_GETMINMAXINFO",
        38 => "WM_PAINTICON",
        39 => "WM_ICONERASEBKGND",
        40 => "WM_NEXTDLGCTL",
        42 => "WM_SPOOLERSTATUS",
        43 => "WM_DRAWITEM",
        44 => "WM_MEASUREITEM",
        45 => "WM_DELETEITEM",
        46 => "WM_VKEYTOITEM",
        47 => "WM_CHARTOITEM",
        48 => "WM_SETFONT",
        49 => "WM_GETFONT",
        50 => "WM_SETHOTKEY",
        51 => "WM_GETHOTKEY",
        55 => "WM_QUERYDRAGICON",
        57 => "WM_COMPAREITEM",
        61 => "WM_GETOBJECT",
        65 => "WM_COMPACTING",
        68 => "WM_COMMNOTIFY",
        70 => "WM_WINDOWPOSCHANGING",
        71 => "WM_WINDOWPOSCHANGED",
        72 => "WM_POWER",
        73 => "WM_COPYGLOBALDATA",
        74 => "WM_COPYDATA",
        75 => "WM_CANCELJOURNAL",
        78 => "WM_NOTIFY",
        80 => "WM_INPUTLANGCHANGEREQUEST",
        81 => "WM_INPUTLANGCHANGE",
        82 => "WM_TCARD",
        83 => "WM_HELP",
        84 => "WM_USERCHANGED",
        85 => "WM_NOTIFYFORMAT",
        123 => "WM_CONTEXTMENU",
        124 => "WM_STYLECHANGING",
        125 => "WM_STYLECHANGED",
        126 => "WM_DISPLAYCHANGE",
        127 => "WM_GETICON",
        128 => "WM_SETICON",
        129 => "WM_NCCREATE",
        130 => "WM_NCDESTROY",
        131 => "WM_NCCALCSIZE",
        132 => "WM_NCHITTEST",
        133 => "WM_NCPAINT",
        134 => "WM_NCACTIVATE",
        135 => "WM_GETDLGCODE",
        136 => "WM_SYNCPAINT",
        160 => "WM_NCMOUSEMOVE",
        161 => "WM_NCLBUTTONDOWN",
        162 => "WM_NCLBUTTONUP",
        163 => "WM_NCLBUTTONDBLCLK",
        164 => "WM_NCRBUTTONDOWN",
        165 => "WM_NCRBUTTONUP",
        166 => "WM_NCRBUTTONDBLCLK",
        167 => "WM_NCMBUTTONDOWN",
        168 => "WM_NCMBUTTONUP",
        169 => "WM_NCMBUTTONDBLCLK",
        171 => "WM_NCXBUTTONDOWN",
        172 => "WM_NCXBUTTONUP",
        173 => "WM_NCXBUTTONDBLCLK",
        255 => "WM_INPUT",
        256 => "WM_KEYDOWN",
        257 => "WM_KEYUP",
        258 => "WM_CHAR",
        259 => "WM_DEADCHAR",
        260 => "WM_SYSKEYDOWN",
        261 => "WM_SYSKEYUP",
        262 => "WM_SYSCHAR",
        263 => "WM_SYSDEADCHAR",
        265 => "WM_UNICHAR",
        266 => "WM_CONVERTREQUEST",
        267 => "WM_CONVERTRESULT",
        268 => "WM_INTERIM",
        269 => "WM_IME_STARTCOMPOSITION",
        270 => "WM_IME_ENDCOMPOSITION",
        271 => "WM_IME_COMPOSITION",
        272 => "WM_INITDIALOG",
        273 => "WM_COMMAND",
        274 => "WM_SYSCOMMAND",
        275 => "WM_TIMER",
        276 => "WM_HSCROLL",
        277 => "WM_VSCROLL",
        278 => "WM_INITMENU",
        279 => "WM_INITMENUPOPUP",
        280 => "WM_SYSTIMER",
        287 => "WM_MENUSELECT",
        288 => "WM_MENUCHAR",
        289 => "WM_ENTERIDLE",
        290 => "WM_MENURBUTTONUP",
        291 => "WM_MENUDRAG",
        292 => "WM_MENUGETOBJECT",
        293 => "WM_UNINITMENUPOPUP",
        294 => "WM_MENUCOMMAND",
        295 => "WM_CHANGEUISTATE",
        296 => "WM_UPDATEUISTATE",
        297 => "WM_QUERYUISTATE",
        305 => "WM_LBTRACKPOINT",
        306 => "WM_CTLCOLORMSGBOX",
        307 => "WM_CTLCOLOREDIT",
        308 => "WM_CTLCOLORLISTBOX",
        309 => "WM_CTLCOLORBTN",
        310 => "WM_CTLCOLORDLG",
        311 => "WM_CTLCOLORSCROLLBAR",
        312 => "WM_CTLCOLORSTATIC",
        512 => "WM_MOUSEMOVE",
        513 => "WM_LBUTTONDOWN",
        514 => "WM_LBUTTONUP",
        515 => "WM_LBUTTONDBLCLK",
        516 => "WM_RBUTTONDOWN",
        517 => "WM_RBUTTONUP",
        518 => "WM_RBUTTONDBLCLK",
        519 => "WM_MBUTTONDOWN",
        520 => "WM_MBUTTONUP",
        521 => "WM_MBUTTONDBLCLK",
        522 => "WM_MOUSEWHEEL",
        523 => "WM_XBUTTONDOWN",
        524 => "WM_XBUTTONUP",
        525 => "WM_XBUTTONDBLCLK",
        526 => "WM_MOUSEHWHEEL",
        528 => "WM_PARENTNOTIFY",
        529 => "WM_ENTERMENULOOP",
        530 => "WM_EXITMENULOOP",
        531 => "WM_NEXTMENU",
        532 => "WM_SIZING",
        533 => "WM_CAPTURECHANGED",
        534 => "WM_MOVING",
        536 => "WM_POWERBROADCAST",
        537 => "WM_DEVICECHANGE",
        544 => "WM_MDICREATE",
        545 => "WM_MDIDESTROY",
        546 => "WM_MDIACTIVATE",
        547 => "WM_MDIRESTORE",
        548 => "WM_MDINEXT",
        549 => "WM_MDIMAXIMIZE",
        550 => "WM_MDITILE",
        551 => "WM_MDICASCADE",
        552 => "WM_MDIICONARRANGE",
        553 => "WM_MDIGETACTIVE",
        560 => "WM_MDISETMENU",
        561 => "WM_ENTERSIZEMOVE",
        562 => "WM_EXITSIZEMOVE",
        563 => "WM_DROPFILES",
        564 => "WM_MDIREFRESHMENU",
        640 => "WM_IME_REPORT",
        641 => "WM_IME_SETCONTEXT",
        642 => "WM_IME_NOTIFY",
        643 => "WM_IME_CONTROL",
        644 => "WM_IME_COMPOSITIONFULL",
        645 => "WM_IME_SELECT",
        646 => "WM_IME_CHAR",
        648 => "WM_IME_REQUEST",
        656 => "WM_IME_KEYDOWN",
        657 => "WM_IME_KEYUP",
        672 => "WM_NCMOUSEHOVER",
        673 => "WM_MOUSEHOVER",
        674 => "WM_NCMOUSELEAVE",
        675 => "WM_MOUSELEAVE",
        768 => "WM_CUT",
        769 => "WM_COPY",
        770 => "WM_PASTE",
        771 => "WM_CLEAR",
        772 => "WM_UNDO",
        773 => "WM_RENDERFORMAT",
        774 => "WM_RENDERALLFORMATS",
        775 => "WM_DESTROYCLIPBOARD",
        776 => "WM_DRAWCLIPBOARD",
        777 => "WM_PAINTCLIPBOARD",
        778 => "WM_VSCROLLCLIPBOARD",
        779 => "WM_SIZECLIPBOARD",
        780 => "WM_ASKCBFORMATNAME",
        781 => "WM_CHANGECBCHAIN",
        782 => "WM_HSCROLLCLIPBOARD",
        783 => "WM_QUERYNEWPALETTE",
        784 => "WM_PALETTEISCHANGING",
        785 => "WM_PALETTECHANGED",
        786 => "WM_HOTKEY",
        791 => "WM_PRINT",
        792 => "WM_PRINTCLIENT",
        793 => "WM_APPCOMMAND",
        799 => "WM_DWMNCRENDERINGCHANGED",
        856 => "WM_HANDHELDFIRST",
        863 => "WM_HANDHELDLAST",
        864 => "WM_AFXFIRST",
        895 => "WM_AFXLAST",
        896 => "WM_PENWINFIRST",
        897 => "WM_RCRESULT",
        898 => "WM_HOOKRCRESULT",
        899 => "WM_GLOBALRCCHANGE",
        900 => "WM_SKB",
        901 => "WM_PENCTL",
        902 => "WM_PENMISC",
        903 => "WM_CTLINIT",
        904 => "WM_PENEVENT",
        911 => "WM_PENWINLAST",
        1024 => "WM_USER+0",
        1025 => "WM_USER+1",
        1026 => "WM_USER+2",
        1027 => "WM_USER+3",
        1028 => "WM_USER+4",
        1029 => "WM_USER+5",
        1030 => "WM_USER+6",
        else => null,
    };
}

pub fn getHitName(hit: win32.LRESULT) ?[]const u8 {
    return switch (hit) {
        win32.HTERROR => "err",
        win32.HTTRANSPARENT => "transprnt",
        win32.HTNOWHERE => "nowhere",
        win32.HTCLIENT => "client",
        win32.HTCAPTION => "caption",
        win32.HTSYSMENU => "sysmnu",
        win32.HTSIZE => "size",
        win32.HTMENU => "menu",
        win32.HTHSCROLL => "hscroll",
        win32.HTVSCROLL => "vscroll",
        win32.HTMINBUTTON => "minbtn",
        win32.HTMAXBUTTON => "max",
        win32.HTLEFT => "left",
        win32.HTRIGHT => "right",
        win32.HTTOP => "top",
        win32.HTTOPLEFT => "topleft",
        win32.HTTOPRIGHT => "topright",
        win32.HTBOTTOM => "bottom",
        win32.HTBOTTOMLEFT => "botmleft",
        win32.HTBOTTOMRIGHT => "botmright",
        win32.HTBORDER => "border",
        win32.HTCLOSE => "close",
        win32.HTHELP => "help",
        else => null,
    };
}
