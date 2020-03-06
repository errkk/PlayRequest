import {Socket} from "phoenix";

export default {
  connect() {
    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    const socket = new Socket("/socket", {params: {_csrf_token: csrfToken}});
    socket.connect();
    return socket;
  }
}
