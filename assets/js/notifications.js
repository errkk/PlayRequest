import {Socket} from "phoenix";

function connect() {
  if (!window.userToken.length) {
    return
  }
  const socket = new Socket("/socket", {params: {token: window.userToken}});

  socket.connect();

  const channel = socket.channel("notifications:*", {})

  channel.join()
    .receive("error", resp => { console.log("Unable to join notifications channel", resp) })
    .receive("ok", () => console.log("Connected"));

  channel.on("like", showNotification);
  channel.on("error", updateError);
  channel.on("play_state", updatePlaystate);
}

function showNotification({track: {artist, name, img}, from: {first_name}}) {
  const msgTitle = `😍 ${first_name} liked ${name}`;
  const options = {
    image: img,
    icon: img,
    body: `${name} – ${artist}`
  };
  if (!("Notification" in window)) {
    return;
  }
  if (Notification.permission === "granted") {
    new Notification(msgTitle, options);
  }
}

function requestNotificationPermission() {
  if (!("Notification" in window)) {
    return;
  }
  Notification.requestPermission();
}

function updateError({ error_code }) {
  if (error_code) {
    document.body.classList.add("error")
  } else {
    console.log("Remove error", document.body.classList)
    document.body.classList.remove("error")
  }
}

function updatePlaystate({state}) {
  // Update this flag for the favicon worker to pick up
  window.playState = state;
}

export default function() {
  requestNotificationPermission();
  connect();
};
