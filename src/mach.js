const original_title = document.title;
const text_decoder = new TextDecoder();
const text_encoder = new TextEncoder();
let log_buf = "";

const mach = {
  canvases: [],
  wasm: undefined,
  events: [],

  init(wasm) {
    this.wasm = wasm;
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

  machCanvasInit(width, height, id) {
    let canvas = document.createElement("canvas");
    canvas.id = "#mach-canvas-" + mach.canvases.length;
    canvas.style.width = width + "px";
    canvas.style.height = height + "px";
    canvas.width = Math.floor(width * window.devicePixelRatio);
    canvas.height = Math.floor(height * window.devicePixelRatio);
    canvas.tabIndex = 1;

    mach.setString(canvas.id, id);

    canvas.addEventListener("contextmenu", (ev) => ev.preventDefault());

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
      cv.canvas.width = width * window.devicePixelRatio;
      cv.canvas.height = height * window.devicePixelRatio;
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

  machPerfNow() {
    return performance.now();
  },
};

export { mach };
