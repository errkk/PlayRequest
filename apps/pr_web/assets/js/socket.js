import {Socket} from "phoenix";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
const socket = new Socket("/socket", {params: {_csrf_token: csrfToken}});

socket.connect();

// Now that you are connected, you can join channels with a topic:
const channel = socket.channel("notifications:like", {})
channel.join()
  .receive("error", resp => { console.log("Unable to join notifications channel", resp) });


function showNotification({track: {artist, name, img}}) {
  const msgTitle = `😍 Sombody liked ${name}`;
  const options = {
    image: img,
    icon: img,
    body: `${name} – ${artist}`
  };
  if (!("Notification" in window)) {
    return;
  }
  if (Notification.permission === "granted") {
  }
  new Notification(msgTitle, options);

}

function requestNotificationPermission() {
  if (!("Notification" in window)) {
    return;
  }
  Notification.requestPermission();
}

requestNotificationPermission();

channel.on("like", showNotification);

export default socket;
