import {Socket} from "phoenix";

function connect() {
  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  const socket = new Socket("/socket", {params: {_csrf_token: csrfToken}});

  socket.connect();

  const channel = socket.channel("notifications:like", {})

  channel.join().receive("error", resp => { console.log("Unable to join notifications channel", resp) });
  channel.on("like", showNotification);
}

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



export default function() {
  requestNotificationPermission();
  connect();
};
