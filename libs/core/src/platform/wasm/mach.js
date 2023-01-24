const text_decoder = new TextDecoder();
const text_encoder = new TextEncoder();

const mach = {
  canvases: [],
  wasm: undefined,
  observer: undefined,
  events: [],
  changes: [],
  wait_timeout: 0,
  log_buf: "",

  init(wasm) {
    mach.wasm = wasm;
    mach.observer = new MutationObserver((mutables) => {
      mutables.forEach((mutable) => {
        mach.canvases.forEach((canvas) => {
          if (mutable.target == canvas) {
            if (mutable.attributeName === "width" ||
              mutable.attributeName === "height" ||
              mutable.attributeName === "style") {
              mutable.target.dispatchEvent(new Event("mach-canvas-resize"));
            }
          }
        });
      })
    })
  },

  getString(str, len) {
    const memory = mach.wasm.exports.memory.buffer;
    return text_decoder.decode(new Uint8Array(memory, str, len));
  },

  setString(str, buf) {
    const memory = mach.wasm.exports.memory.buffer;
    const strbuf = text_encoder.encode(str);
    const outbuf = new Uint8Array(memory, buf, strbuf.length);
    for (let i = 0; i < strbuf.length; i += 1) {
      outbuf[i] = strbuf[i];
    }
  },

  machLogWrite(str, len) {
    mach.log_buf += mach.getString(str, len);
  },

  machLogFlush() {
    console.log(log_buf);
    mach.log_buf = "";
  },

  machPanic(str, len) {
    throw Error(mach.getString(str, len));
  },

  machCanvasInit(id) {
    let canvas = document.createElement("canvas");
    canvas.id = "#mach-canvas-" + mach.canvases.length;
    canvas.style.border = "1px solid";
    canvas.style.position = "absolute";
    canvas.style.display = "block";
    canvas.tabIndex = 1;

    mach.observer.observe(canvas, { attributes: true });

    mach.setString(canvas.id, id);

    canvas.addEventListener("contextmenu", (ev) => ev.preventDefault());

    canvas.addEventListener("keydown", (ev) => {
      if (ev.repeat) {
        mach.events.push(...[EventCode.key_repeat, convertKeyCode(ev.code)]);
      } else {
        mach.events.push(...[EventCode.key_press, convertKeyCode(ev.code)]);
      }
    });

    canvas.addEventListener("keyup", (ev) => {
      mach.events.push(...[EventCode.key_release, convertKeyCode(ev.code)]);
    });

    canvas.addEventListener("mousemove", (ev) => {
      mach.events.push(...[EventCode.mouse_motion, ev.clientX, ev.clientY]);
    });

    canvas.addEventListener("mousedown", (ev) => {
      mach.events.push(...[EventCode.mouse_press, ev.button]);
    });

    canvas.addEventListener("mouseup", (ev) => {
      mach.events.push(...[EventCode.mouse_release, ev.button]);
    });

    canvas.addEventListener("wheel", (ev) => {
      mach.events.push(...[EventCode.mouse_scroll, ev.deltaX, ev.deltaY]);
    });

    canvas.addEventListener("mach-canvas-resize", (ev) => {
      const cv_index = mach.canvases.findIndex((el) => el === ev.currentTarget);
      const cv = mach.canvases[cv_index];
      mach.events.push(...[EventCode.framebuffer_resize, cv.width, cv.height, window.devicePixelRatio]);
    });

    canvas.addEventListener("focus", (ev) => {
      mach.events.push(...[EventCode.focus_gained]);
    });

    canvas.addEventListener("blur", (ev) => {
      mach.events.push(...[EventCode.focus_lost]);
    });

    document.body.appendChild(canvas);
    return mach.canvases.push(canvas) - 1;
  },

  machCanvasDeinit(canvas) {
    if (mach.canvases[canvas] != undefined) {
      mach.canvases.splice(canvas, 1);
    }
  },

  machCanvasFramebufferWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.width;
  },

  machCanvasFramebufferHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.height;
  },

  machCanvasSetTitle(canvas, title, len) {
    // TODO
  },

  machCanvasSetDisplayMode(canvas, mode) {
    const cv = mach.canvases[canvas];
    switch (mode) {
      case DisplayMode.windowed:
        document.exitFullscreen();
        break;
      case DisplayMode.fullscreen:
        cv.requestFullscreen();
        break;
    }
  },

  machCanvasDisplayMode(canvas) {
    if (mach.canvases[canvas].fullscreenElement == null) {
      return DisplayMode.windowed;
    } else {
      return DisplayMode.fullscreen;
    }
  },

  machCanvasSetBorder(canvas, value) {
    // TODO
  },

  machCanvasBorder(canvas) {
    // TODO
  },

  machCanvasSetHeadless(canvas, value) {
    // TODO
  },

  machCanvasHeadless(canvas) {
    // TODO
  },

  machCanvasSetVSync(canvas, mode) {
    // TODO
  },

  machCanvasVSync(canvas) {
    // TODO
  },

  machCanvasSetSize(canvas, width, height) {
    const cv = mach.canvases[canvas];
    if (width > 0 && height > 0) {
      cv.style.width = width + "px";
      cv.style.height = height + "px";
      cv.width = Math.floor(width * window.devicePixelRatio);
      cv.height = Math.floor(height * window.devicePixelRatio);
    }
  },

  machCanvasWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.width / window.devicePixelRatio;
  },

  machCanvasHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.height / window.devicePixelRatio;
  },

  machCanvasSetSizeLimit(canvas, min_width, min_height, max_width, max_height) {
    const cv = mach.canvases[canvas];
    if (min_width == -1) {
      cv.style.minWidth = "inherit"
    } else {
      cv.style.minWidth = min_width + "px";
    }
    if (min_width == -1) {
      cv.style.minHeight = "inherit"
    } else {
      cv.style.minHeight = min_height + "px";
    }
    if (min_width == -1) {
      cv.style.maxWidth = "inherit"
    } else {
      cv.style.maxWidth = max_width + "px";
    }
    if (min_width == -1) {
      cv.style.maxHeight = "inherit"
    } else {
      cv.style.maxHeight = max_height + "px";
    }
  },

  machCanvasMinWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.style.minWidth;
  },

  machCanvasMinHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.style.minHeight;
  },

  machCanvasMaxWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.style.maxWidth;
  },

  machCanvasMaxHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.style.maxHeight;
  },

  machSetCursorMode(canvas, mode) {
    const cv = mach.canvases[canvas];
    switch (mode) {
      case CursorMode.normal:
        cv.style.cursor = 'default';
        break;
      case CursorMode.hidden:
        cv.style.cursor = 'none';
        break;
      case CursorMode.hidden:
        cv.style.cursor = 'none';
        break;
    }
  },

  machCursorMode(canvas) {
    switch (mach.canvases[canvas].style.cursor) {
      case 'none': return CursorMode.hidden;
      default: return CursorMode.normal;
    }
  },

  machSetCursorShape(canvas, shape) {
    const cv = mach.canvases[canvas];
    switch (shape) {
      case CursorShape.arrow:
        cv.style.cursor = 'default';
        break;
      case CursorShape.ibeam:
        cv.style.cursor = 'text';
        break;
      case CursorShape.crosshair:
        cv.style.cursor = 'crosshair';
        break;
      case CursorShape.pointing_hand:
        cv.style.cursor = 'pointer';
        break;
      case CursorShape.resize_ew:
        cv.style.cursor = 'ew-resize';
        break;
      case CursorShape.resize_ns:
        cv.style.cursor = 'ns-resize';
        break;
      case CursorShape.resize_nwse:
        cv.style.cursor = 'nwse-resize';
        break;
      case CursorShape.resize_nesw:
        cv.style.cursor = 'nesw-resize';
        break;
      case CursorShape.resize_all:
        cv.style.cursor = 'move';
        break;
      case CursorShape.not_allowed:
        cv.style.cursor = 'not-allowed';
        break;
    }
  },

  machCursorShape(canvas) {
    switch (mach.canvases[canvas].style.cursor) {
      case 'default': return CursorShape.arrow;
      case 'text': return CursorShape.ibeam;
      case 'crosshair': return CursorShape.crosshair;
      case 'pointer': return CursorShape.pointing_hand;
      case 'ew-resize': return CursorShape.resize_ew;
      case 'ns-resize': return CursorShape.resize_ns;
      case 'nwse-resize': return CursorShape.resize_nwse;
      case 'nesw-resize': return CursorShape.resize_nesw;
      case 'move': return CursorShape.resize_all;
      case 'not-allowed': return CursorShape.not_allowed;
    }
  },

  machSetWaitTimeout(timeout) {
    mach.wait_timeout = timeout;
  },

  machHasEvent() {
    return mach.events.length > 0;
  },

  machEventShift() {
    if (mach.machHasEvent())
      return mach.events.shift();

    return -1;
  },

  machEventShiftFloat() {
    return mach.machEventShift();
  },

  machPerfNow() {
    return performance.now();
  },
};

function convertKeyCode(code) {
  const k = Key[code];
  if (k != undefined)
    return k;
  return 118; // Unknown
}

const Key = {
  KeyA: 0,
  KeyB: 1,
  KeyC: 2,
  KeyD: 3,
  KeyE: 4,
  KeyF: 5,
  KeyG: 6,
  KeyH: 7,
  KeyI: 8,
  KeyJ: 9,
  KeyK: 10,
  KeyL: 11,
  KeyM: 12,
  KeyN: 13,
  KeyO: 14,
  KeyP: 15,
  KeyQ: 16,
  KeyR: 17,
  KeyS: 18,
  KeyT: 19,
  KeyU: 20,
  KeyV: 21,
  KeyW: 22,
  KeyX: 23,
  KeyY: 24,
  KeyZ: 25,
  Digit0: 26,
  Digit1: 27,
  Digit2: 28,
  Digit3: 29,
  Digit4: 30,
  Digit5: 31,
  Digit6: 32,
  Digit7: 33,
  Digit8: 34,
  Digit9: 35,
  F1: 36,
  F2: 37,
  F3: 38,
  F4: 39,
  F5: 40,
  F6: 41,
  F7: 42,
  F8: 43,
  F9: 44,
  F10: 45,
  F11: 46,
  F12: 47,
  F13: 48,
  F14: 49,
  F15: 50,
  F16: 51,
  F17: 52,
  F18: 53,
  F19: 54,
  F20: 55,
  F21: 56,
  F22: 57,
  F23: 58,
  F24: 59,
  F25: 60,
  NumpadDivide: 61,
  NumpadMultiply: 62,
  NumpadSubtract: 63,
  NumpadAdd: 64,
  Numpad0: 65,
  Numpad1: 66,
  Numpad2: 67,
  Numpad3: 68,
  Numpad4: 69,
  Numpad5: 70,
  Numpad6: 71,
  Numpad7: 72,
  Numpad8: 73,
  Numpad9: 74,
  NumpadDecimal: 75,
  NumpadEqual: 76,
  NumpadEnter: 77,
  Enter: 78,
  Escape: 79,
  Tab: 80,
  ShiftLeft: 81,
  ShiftRight: 82,
  ControlLeft: 83,
  ControlRight: 84,
  AltLeft: 85,
  AltRight: 86,
  OSLeft: 87,
  MetaLeft: 87,
  OSRight: 88,
  MetaRight: 88,
  ContextMenu: 89,
  NumLock: 90,
  CapsLock: 91,
  PrintScreen: 92,
  ScrollLock: 93,
  Pause: 94,
  Delete: 95,
  Home: 96,
  End: 97,
  PageUp: 98,
  PageDown: 99,
  Insert: 100,
  ArrowLeft: 101,
  ArrowRight: 102,
  ArrowUp: 103,
  ArrowDown: 104,
  Backspace: 105,
  Space: 106,
  Minus: 107,
  Equal: 108,
  BracketLeft: 109,
  BracketRight: 110,
  Backslash: 111,
  Semicolon: 112,
  Quote: 113,
  Comma: 114,
  Period: 115,
  Slash: 116,
  Backquote: 117,
};

const EventCode = {
  key_press: 0,
  key_repeat: 1,
  key_release: 2,
  char_input: 3,
  mouse_motion: 4,
  mouse_press: 5,
  mouse_release: 6,
  mouse_scroll: 7,
  framebuffer_resize: 8,
  focus_gained: 9,
  focus_lost: 10,
  close: 11,
};

const DisplayMode = {
  windowed: 0,
  fullscreen: 1,
};

const CursorMode = {
  normal: 0,
  hidden: 1,
  disabled: 2,
};

const CursorShape = {
  arrow: 0,
  ibeam: 1,
  crosshair: 2,
  pointing_hand: 3,
  resize_ew: 4,
  resize_ns: 5,
  resize_nwse: 6,
  resize_nesw: 7,
  resize_all: 8,
  not_allowed: 9,
};

export { mach };
