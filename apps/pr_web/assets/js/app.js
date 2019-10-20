// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live");
liveSocket.connect();

const searchInput = document.getElementById("search");

if (searchInput) {
  window.addEventListener("keyup", (evt) => {
    if (evt.key === "/") {
      evt.preventDefault();
      searchInput.focus();
    }
  }, false);
}

window.addEventListener("keyup", evt => {
  if (evt.key === "Escape") {
    liveSocket.channel.push({
      event: "clear_info"
    });
  }
}, false);

function getChannel() {
  return Object.values(liveSocket.views).filter(v => v.view === 'PRWeb.PlaybackLive')[0].channel;
}
window.clearInfo = () => {
getChannel().push("event", {event: "clear_info"});
}

window.getChannel = getChannel;
window.ls = liveSocket;
