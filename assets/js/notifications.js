import { Socket } from "phoenix";
import confetti from "canvas-confetti";

function connect() {
  if (!window.userToken.length) {
    return;
  }
  const socket = new Socket("/socket", { params: { token: window.userToken } });

  socket.connect();

  const channel = socket.channel("notifications:*", {});

  channel
    .join()
    .receive("error", (resp) => {
      console.log("Unable to join notifications channel", resp);
    })
    .receive("ok", () => console.log("Connected"));

  channel.on("like", showNotification);
  channel.on("error", updateError);
  channel.on("play_state", updatePlaystate);
}

const confettis = {
  like: confetti,
  super_like: bigConfetti,
  burn: () => {},
};

window.addEventListener(
  "phx:point-given",
  ({ detail: { reason } }) => {
    // Point given BY this session
    confettis[reason]();
  },
  false,
);

function showNotification({
  track: { artist, name, img },
  from: { first_name },
  reason,
}) {
  const titles = {
    like: `😍 ${first_name} liked ${name}`,
    super_like: `🤩 ${first_name} SUPERLIKED ${name}!`,
    burn: `🔥 Oh dear ${name}`,
  };
  const msgTitle = titles[reason];
  // Point received
  confettis[reason]();
  const options = {
    image: img,
    icon: img,
    body: `${name} – ${artist}`,
  };
  if (!("Notification" in window)) {
    return;
  }
  if (Notification.permission === "granted") {
    new Notification(msgTitle, options);
  }
}

const DISMISSED_KEY = "notificationPromptDismissed";

function isDismissed() {
  try {
    return localStorage.getItem(DISMISSED_KEY) === "1";
  } catch (e) {
    return false;
  }
}

function setDismissed() {
  try {
    localStorage.setItem(DISMISSED_KEY, "1");
  } catch (e) {}
}

function showPermissionPrompt() {
  if (!("Notification" in window)) return;
  if (Notification.permission !== "default") return;
  if (isDismissed()) return;

  const el = document.createElement("div");
  el.className = "notify-prompt";
  el.setAttribute("role", "dialog");
  el.innerHTML = `
    <p class="notify-prompt__text">Get notified when people like your tracks?</p>
    <div class="notify-prompt__actions">
      <button type="button" class="button" data-action="enable">Enable</button>
      <button type="button" class="button" data-action="dismiss">Not now</button>
    </div>
  `;

  const close = () => el.remove();

  el.querySelector('[data-action="dismiss"]').addEventListener("click", () => {
    setDismissed();
    close();
  });

  el.querySelector('[data-action="enable"]').addEventListener("click", () => {
    // Older Safari only supports the callback form
    const done = (permission) => {
      if (permission === "default") setDismissed();
      close();
    };
    const result = Notification.requestPermission(done);
    if (result && result.then) result.then(done);
  });

  document.body.appendChild(el);
}

function updateError({ error_code }) {
  if (error_code) {
    document.body.classList.add("error");
  } else {
    console.log("Remove error", document.body.classList);
    document.body.classList.remove("error");
  }
}

function updatePlaystate({ state }) {
  // Update this flag for the favicon worker to pick up
  window.playState = state;
}

export default function () {
  if (window.userToken.length) showPermissionPrompt();
  connect();
}

var duration = 10 * 1000;
var end = Date.now() + duration;

function bigConfetti() {
  // launch a few confetti from the left edge
  confetti({
    particleCount: 7,
    angle: 60,
    spread: 55,
    origin: { x: 0 },
  });
  // and launch a few from the right edge
  confetti({
    particleCount: 7,
    angle: 120,
    spread: 55,
    origin: { x: 1 },
  });

  // keep going until we are out of time
  if (Date.now() < end) {
    setTimeout(bigConfetti, 10);
  }
}
