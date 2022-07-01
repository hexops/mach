const original_title = document.title;
const text_decoder = new TextDecoder();
const text_encoder = new TextEncoder();
let log_buf = "";

function convertKeyCode(code) {
  const mapKeyCode = {
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

  const k = mapKeyCode[code];
  if (k != undefined)
    return k;
  return 118; // Unknown
}

const mach = {
  canvases: [],
  wasm: undefined,
  observer: undefined,
  events: [],
  changes: [],
  wait_event_timeout: 0,

  init(wasm) {
    this.wasm = wasm;
    this.observer = new MutationObserver((mutables) => {
      mutables.forEach((mutable) => {
        if (mutable.type === 'attributes') {
          if (mutable.attributeName === "width" || mutable.attributeName === "height") {
            mutable.target.dispatchEvent(new Event("mach-canvas-resize"));
          }
        }
      })
    })
  },

  getString(str, len) {
    const memory = mach.wasm.exports.memory.buffer;
    return text_decoder.decode(new Uint8Array(memory, str, len));
  },

  setString(str, buf) {
    const memory = this.wasm.exports.memory.buffer;
    const strbuf = text_encoder.encode(str);
    const outbuf = new Uint8Array(memory, buf, strbuf.length);
    for (let i = 0; i < strbuf.length; i += 1) {
        outbuf[i] = strbuf[i];
    }
  },

  machLogWrite(str, len) {
    log_buf += mach.getString(str, len);
  },

  machLogFlush() {
    console.log(log_buf);
    log_buf = "";
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
            mach.events.push(...[2, convertKeyCode(ev.code)]);
        } else {
            mach.events.push(...[1, convertKeyCode(ev.code)]);
        }
    });

    canvas.addEventListener("keyup", (ev) => {
      mach.events.push(...[3, convertKeyCode(ev.code)]);
    });

    canvas.addEventListener("mousemove", (ev) => {
      mach.events.push(...[4, ev.clientX, ev.clientY]);
	});

    canvas.addEventListener("mousedown", (ev) => {
      mach.events.push(...[5, ev.button]);
	});

    canvas.addEventListener("mouseup", (ev) => {
      mach.events.push(...[6, ev.button]);
	});

    canvas.addEventListener("wheel", (ev) => {
      mach.events.push(...[7, ev.deltaX, ev.deltaY]);
	});

    canvas.addEventListener("focus", (ev) => {
        mach.events.push(...[8]);
    });

    canvas.addEventListener("blur", (ev) => {
        mach.events.push(...[9]);
    });

    canvas.addEventListener("mach-canvas-resize", (ev) => {
      const cv_index = mach.canvases.findIndex((el) => el.canvas === ev.currentTarget);
      const cv = mach.canvases[cv_index];
      mach.changes.push(...[1, cv.canvas.width, cv.canvas.height, window.devicePixelRatio]);
    });

    document.body.appendChild(canvas);
    return mach.canvases.push({ canvas: canvas, title: undefined }) - 1;
  },

  machCanvasDeinit(canvas) {
    if (mach.canvases[canvas] != undefined) {
      mach.canvases.splice(canvas, 1);
    }
  },

  machCanvasSetTitle(canvas, title, len) {
    const str = len > 0 ?
      mach.getString(title, len) :
      original_title;

    mach.canvases[canvas].title = str;
  },

  machCanvasSetSize(canvas, width, height) {
    const cv = mach.canvases[canvas];
    if (width > 0 && height > 0) {
      cv.canvas.style.width = width + "px";
      cv.canvas.style.height = height + "px";
      cv.canvas.width = Math.floor(width * window.devicePixelRatio);
      cv.canvas.height = Math.floor(height * window.devicePixelRatio);
    }
  },

  machCanvasSetFullscreen(canvas, value) {
    const cv = mach.canvases[canvas];
    if (value) {
      cv.canvas.style.border = "0px";
      cv.canvas.style.width = "100%";
      cv.canvas.style.height = "100%";
      cv.canvas.style.top = "0";
      cv.canvas.style.left = "0";
      cv.canvas.style.margin = "0px";
    } else {
      cv.canvas.style.border = "1px solid;"
      cv.canvas.style.top = "2px";
      cv.canvas.style.left = "2px";
    }
  },

  machCanvasGetWindowWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.width / window.devicePixelRatio;
  },

  machCanvasGetWindowHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.height / window.devicePixelRatio;
  },

  machCanvasGetFramebufferWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.width;
  },

  machCanvasGetFramebufferHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.height;
  },

  machEmitCloseEvent() {
    window.dispatchEvent(new Event("mach-close"));
  },

  machSetMouseCursor(cursor_ptr, len) {
    let mach_name = mach.getString(cursor_ptr, len);

    if (mach_name === 'arrow') document.body.style.cursor = 'default';
    else if (mach_name === 'ibeam') document.body.style.cursor = 'text';
    else if (mach_name === 'crosshair') document.body.style.cursor = 'crosshair';
    else if (mach_name === 'pointing_hand') document.body.style.cursor = 'pointer';
    else if (mach_name === 'resize_ew') document.body.style.cursor = 'ew-resize';
    else if (mach_name === 'resize_ns') document.body.style.cursor = 'ns-resize';
    else if (mach_name === 'resize_nwse') document.body.style.cursor = 'nwse-resize';
    else if (mach_name === 'resize_nesw') document.body.style.cursor = 'nesw-resize';
    else if (mach_name === 'resize_all') document.body.style.cursor = 'move';
    else if (mach_name === 'not_allowed') document.body.style.cursor = 'not-allowed';
    else {
      console.log("machSetMouseCursor failed for " + mach_name);
    }
  },

  machSetWaitEvent(timeout) {
    mach.wait_event_timeout = timeout;  
  },

  machHasEvent() {
    return (mach.events.length > 0);
  },

  machEventShift() {
    if (mach.events.length === 0)
      return 0;

    return mach.events.shift();
  },

  machEventShiftFloat() {
    return mach.machEventShift();
  },

  machChangeShift() {
    if (mach.changes.length === 0)
      return 0;

    return mach.changes.shift();
  },

  machPerfNow() {
    return performance.now();
  },
};

export { mach };
