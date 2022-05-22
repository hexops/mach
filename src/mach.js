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
    canvas.width = width;
    canvas.height = height;
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
      cv.canvas.width = width;
      cv.canvas.height = height;
    }
  },

  machCanvasGetWidth(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.width;
  },

  machCanvasGetHeight(canvas) {
    const cv = mach.canvases[canvas];
    return cv.canvas.height;
  },
};

export { mach };
