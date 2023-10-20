// Import dependencies
//
import "phoenix_html";
import { LiveSocket } from "phoenix_live_view";
import { Socket } from "phoenix";

import initGhost from "./ghost";
import notifications from "./notifications";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});
liveSocket.connect();

// Load the ghost up after live view connects
const socket = liveSocket.getSocket();
socket.onOpen(() => {
  setTimeout(initGhost, 1000);
});

const searchInput = document.getElementById("search");

if (searchInput) {
  window.addEventListener(
    "load",
    (_evt) => {
      searchInput.focus();
    },
    false,
  );
  window.addEventListener(
    "keyup",
    (evt) => {
      if (evt.key === "f") {
        evt.preventDefault();
        searchInput.focus();
      }
    },
    false,
  );
}

notifications();
