import { Socket } from "phoenix";
import confetti from "canvas-confetti";

function connect() {
  if (!window.userToken.length) {
    return
  }
  const socket = new Socket("/socket", { params: { token: window.userToken } });

  socket.connect();


  const channel = socket.channel("notifications:*", {})

  channel.join()
    .receive("error", resp => { console.log("Unable to join notifications channel", resp) })
    .receive("ok", () => console.log("Connected"));

  channel.on("like", showNotification);
  channel.on("error", updateError);
  channel.on("play_state", updatePlaystate);
}

const confettis = {
  like: confetti,
  super_like: bigConfetti,
  burn: () => { },
}


window.addEventListener("phx:point-given", ({ detail: { reason } }) => {
  confettis[reason]();
}, false)

function showNotification({ track: { artist, name, img }, from: { first_name }, reason }) {
  const titles = {
    like: `😍 ${first_name} liked ${name}`,
    super_like: `🤩 ${first_name} SUPERLIKED ${name}!`,
    burn: `🔥 Oh dear ${name}`,
  }
  const msgTitle = titles[reason];
  confettis[reason]()
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

function updatePlaystate({ state }) {
  // Update this flag for the favicon worker to pick up
  window.playState = state;
}

export default function() {
  requestNotificationPermission();
  connect();
};

var duration = 20 * 1000;
var end = Date.now() + duration;

function bigConfetti() {
  // launch a few confetti from the left edge
  confetti({
    particleCount: 7,
    angle: 60,
    spread: 55,
    origin: { x: 0 }
  });
  // and launch a few from the right edge
  confetti({
    particleCount: 7,
    angle: 120,
    spread: 55,
    origin: { x: 1 }
  });

  // keep going until we are out of time
  if (Date.now() < end) {
    requestAnimationFrame(bigConfetti);
  }
};
