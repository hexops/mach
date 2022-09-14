let evtSource = new EventSource("/notify");

function setup() {
  evtSource.addEventListener("message", function (e) {
    if (e.data === "reload") {
      window.location.reload();
    }
  });
}

export default setup;
