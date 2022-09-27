import { mach } from "./mach.js";

function _handleMessage(msg) {
  console.log(msg.data);
  //console.log(mach.getString(msg.str, msg.len));
}

let sysaudio = {
  audio: null,
  worklet: null,
  
  async init(module, memory) {
    sysaudio.audio = new AudioContext();
    await sysaudio.audio.audioWorklet.addModule("./mach-sysaudio-worklet.js", );
    
    console.log(module, memory);

    sysaudio.worklet = new AudioWorkletNode(sysaudio.audio, "WasmProcessor", { processorOptions: {
      memory: memory,
      module: module,
    }});
    sysaudio.worklet.port.onmessage = _handleMessage;
    sysaudio.worklet.connect(sysaudio.audio.destination);
  },
  
  start(stack_pointer) {
    sysaudio.worklet.port.postMessage(stack_pointer);
    sysaudio.audio.resume();
  },

  pause() {
    sysaudio.audio.suspend();
  },
};

export { sysaudio };
