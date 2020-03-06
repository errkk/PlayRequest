function connect(socket) {
  const channel = socket.channel("notifications:like", {})
  channel.join().receive("error", resp => { console.log("Unable to join notifications channel", resp) });
  channel.on("like", showNotification);
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
  }
  new Notification(msgTitle, options);

}

function requestNotificationPermission() {
  if (!("Notification" in window)) {
    return;
  }
  Notification.requestPermission();
}



export default function(socket) {
  requestNotificationPermission();
  connect(socket);
};
