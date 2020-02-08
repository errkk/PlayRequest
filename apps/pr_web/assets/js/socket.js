import {Socket} from "phoenix";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const socket = new Socket("/socket", {params: {_csrf_token: csrfToken}});

socket.connect();

// Now that you are connected, you can join channels with a topic:
const channel = socket.channel("notification", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) });

export default socket;
