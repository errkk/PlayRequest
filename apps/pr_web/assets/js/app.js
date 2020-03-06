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
import LiveSocket from "phoenix_live_view"
import {Socket} from "phoenix"

import favicon from "./favicon"
import PRSocket from "./socket";
import notifications from "./notifications";
import germs from "./germs";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}});
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

const socket = PRSocket.connect();
favicon();
notifications(socket);
germs(socket);
