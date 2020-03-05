import {Socket} from "phoenix";
import h337 from 'heatmap.js';

const germs =  (socket) => {
  const domElement = document.getElementById("content");
  const channel = socket.channel("mouse:position", {})
  const heatmap = h337.create({
    container: domElement
  });

  channel.join().receive("error", resp => { console.log("Unable to join coronavirus channel", resp) });
  channel.on("mouse:position", ({x, y}) => {
    heatmap.addData({ x, y, value: 1 });
  });

  domElement.addEventListener('mousemove', (evt) => {
    channel.push("mouse:position", {x: evt.layerX, y: evt.layerY}, 100);
  });
};

function connect() {
  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  const socket = new Socket("/socket", {params: {_csrf_token: csrfToken}});

  socket.connect();

  const channel = socket.channel("notifications:like", {})

  channel.join().receive("error", resp => { console.log("Unable to join notifications channel", resp) });
  channel.on("like", showNotification);

  germs(socket);
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



export default function() {
  requestNotificationPermission();
  connect();
};
