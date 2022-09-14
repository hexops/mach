import AnsiUp from "./ansi_up.js";
const ansiup = new AnsiUp;

let evtSource = new EventSource("/notify");

function setup() {
	evtSource.addEventListener("built", function (e) {
		window.location.reload();
	});
	evtSource.addEventListener("build_error", function (e) {
		if (document.getElementById("error-screen") == null) {
			let es = document.createElement("div");
			es.id = "error-screen";
			es.style.cssText = error_screen_css;
			let h2 = document.createElement("h2");
			let pre = document.createElement("pre");
			h2.textContent = "An error occurred while building:";
			h2.style.cssText = error_screen_h2_css;
			pre.innerHTML = ansiup.ansi_to_html(e.data);
			pre.style.cssText = error_screen_pre_css;
			es.appendChild(h2);
			es.appendChild(pre);
			document.body.appendChild(es);
			console.error(e.data);
		} else {
			document.getElementById("error-screen").
				getElementsByTagName("pre").innerHTML = ansiup.ansi_to_html(e.data);
		}
	});
}

const error_screen_css =
	"position: absolute;" +
	"width: 100vw;" +
	"height: 100vh;" +
	"top: 0;" +
	"left: 0;" +
	"background: rgba(0, 0, 0, 0.85);" +
	"font-family: system-ui, monospace;" +
	"font-size: 16pt;" +
	"padding: 20px;" +
	"box-sizing: border-box;";

const error_screen_h2_css =
	"color: white;" +
	"margin-top: 0;";

const error_screen_pre_css =
	"border: 2px solid rgb(205, 92, 92);" +
	"padding: 10px;" +
	"background: rgba(0, 0, 0, 0.5);" +
	"font-size: 12pt;" +
	"white-space: pre-wrap;" +
	"overflow: hidden;" +
	"color: lightgray;";

export default setup;
