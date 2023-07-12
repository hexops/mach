import ansi_to_html from "./ansi_to_html.js";

let evtSource = new EventSource("/notify");

function setup() {
	evtSource.addEventListener("building", function (e) {
		// TODO
	});
	evtSource.addEventListener("built", function (e) {
		window.location.reload();
	});
	evtSource.addEventListener("compile_error", function (e) {
		createErrorScreen("An error occurred while building:", e.data)
	});
	evtSource.addEventListener("stopped", function (e) {
		createErrorScreen("The build process has stopped unexpectedly:", e.data)
	});
}

function createErrorScreen(msg, data) {
	if (document.getElementById("error-screen") == null) {
		let es = document.createElement("div");
		es.id = "error-screen";
		es.style.cssText = error_screen_css;
		let h2 = document.createElement("h2");
		let pre = document.createElement("pre");
		h2.textContent = msg;
		h2.style.cssText = error_screen_h2_css;
		pre.innerHTML = ansi_to_html.toHtml(data);
		pre.style.cssText = error_screen_pre_css;
		es.appendChild(h2);
		es.appendChild(pre);
		document.body.appendChild(es);

		// atm ANSI escape codes only works in chromium based browsers
		if (!!window.chrome)
			console.log(data);
	} else {
		document.getElementById("error-screen").
			getElementsByTagName("pre").innerHTML = ansi_to_html.toHtml(data);
	}
}

const error_screen_css =
	"position: absolute;" +
	"width: 100vw;" +
	"height: 100vh;" +
	"top: 0;" +
	"left: 0;" +
	"background: rgba(0, 0, 0, 0.8);" +
	"font-family: system-ui, monospace;" +
	"font-size: 16pt;" +
	"padding: 20px;" +
	"box-sizing: border-box;" +
	"color: white;" +
	"z-index: 1;";

const error_screen_h2_css = "margin-top: 0;";

const error_screen_pre_css =
	"border-top: 8px solid #A00;" +
	"padding: 10px;" +
	"background: black;" +
	"font-size: 12pt;" +
	"white-space: pre-wrap;" +
	"overflow: hidden;";

export default setup;