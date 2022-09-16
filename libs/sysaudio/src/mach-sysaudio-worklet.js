registerProcessor("WasmProcessor", class WasmProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();

    this.memory = options.processorOptions.memory;
    this.instance = new WebAssembly.Instance(options.processorOptions.module, {
      mach,
      sysjs,
      sysaudio,
      env: { memory: this.memory }
    });

    sysjs.init(this.instance, this.memory, this.port);
    mach.init(this.instance, this.memory, this.port);
  }
  
  process(inputs, outputs) {
    const num_channels = outputs[0].length;
    const num_samples = outputs[0][0].length;
    const sizeof_f32 = 4;
    
    console.log(num_channels, num_samples, sizeof_f32);

    const result_buffer = this.instance.exports.audioProcessEvent(sampleRate, num_channels, num_samples);
    if (result_buffer !== 0) {
      for (let i = 0; i < num_channels; i += 1) {
        const pointer = result_buffer + i * num_samples * sizeof_f32;
        outputs[0][i].set(new Float32Array(this.memory.buffer, pointer, num_samples));
      }
    }

    return true;
  }
});

// stub out all the other APIs
const sysaudio = {
  start() {},
  pause() {},
};

const mach = {
  init(wasm, memory, port) {
    this.port = port;    
  },

  getString(str, len) {console.error("should not be called");},
  setString(str, buf) {console.error("should not be called");},
  machLogWrite(str, len) {console.error("should not be called");},
  machLogFlush() {console.error("should not be called");},
  machCanvasInit(id) {console.error("should not be called");},
  machCanvasDeinit(canvas) {console.error("should not be called");},
  machCanvasSetTitle(canvas, title, len) {console.error("should not be called");},
  machCanvasSetSize(canvas, width, height) {console.error("should not be called");},
  machCanvasSetFullscreen(canvas, value) {console.error("should not be called");},
  machCanvasGetWindowWidth(canvas) {console.error("should not be called");},
  machCanvasGetWindowHeight(canvas) {console.error("should not be called");},
  machCanvasGetFramebufferWidth(canvas) {console.error("should not be called");},
  machCanvasGetFramebufferHeight(canvas) {console.error("should not be called");},
  machEmitCloseEvent() {console.error("should not be called");},
  machSetMouseCursor(cursor_ptr, len) {console.error("should not be called");},
  machSetWaitEvent(timeout) {console.error("should not be called");},
  machHasEvent() {console.error("should not be called");},
  machEventShift() {console.error("should not be called");},
  machEventShiftFloat() {console.error("should not be called");},
  machChangeShift() {console.error("should not be called");},

  machPanic(str, len) {
    mach.port.postMessage({str, len});
    throw Error("Panic in audio code!", str, len);
  },

  machPerfNow() {
    return performance.now();
  },
};

const sysjs = {
  init(wasm, memory, port) { this.port = port; },

  addValue(value) {console.error("should not be called");},
  zigCreateMap() {console.error("should not be called");},
  zigCreateArray() {console.error("should not be called");},
  zigCreateString(str, len) {console.error("should not be called");},
  zigCreateFunction(id, captures, len) {console.error("should not be called");},
  getType(value) {console.error("should not be called");},
  writeObject(block, data, type) {console.error("should not be called");},
  readObject(block, memory) {console.error("should not be called");},
  getPropertyEx(prop, ret_ptr, offset) {console.error("should not be called");},
  getProperty(prop, ret_ptr) {console.error("should not be called");},
  zigGetProperty(id, name, len, ret_ptr) {console.error("should not be called");},
  zigSetProperty(id, name, len, set_ptr) {console.error("should not be called");},
  zigDeleteProperty(id, name, len) {console.error("should not be called");},
  zigGetIndex(id, index, ret_ptr) {console.error("should not be called");},
  zigSetIndex(id, index, set_ptr) {console.error("should not be called");},
  zigDeleteIndex(id, index) {console.error("should not be called");},
  zigCopyBytes(id, bytes, expected_length) {console.error("should not be called");},
  zigGetAttributeCount(id) {console.error("should not be called");},
  zigCleanupObject(id) {console.error("should not be called");},
  zigGetStringLength(val_id) {console.error("should not be called");},
  zigGetString(val_id, ptr) {console.error("should not be called");},
  zigValueEqual(val, other) {console.error("should not be called");},
  zigValueInstanceOf(val, other) {console.error("should not be called");},
  functionCall(func, this_param, args, args_len, ret_ptr) {console.error("should not be called");},
  zigFunctionCall(id, name, len, args, args_len, ret_ptr) {console.error("should not be called");},
  zigFunctionInvoke(id, args, args_len, ret_ptr) {console.error("should not be called");},
  zigGetParamCount(id) {console.error("should not be called");},
  zigConstructType(id, args, args_len) {console.error("should not be called");},
  wzLogWrite(str, len) {console.error("should not be called");},
  wzLogFlush() {console.error("should not be called");},

  wzPanic(str, len) {
    sysjs.port.postMessage({str, len});
    throw Error("Panic in audio code!", str, len);
  },
};

