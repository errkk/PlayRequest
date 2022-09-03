export const ICON_SIZE = 32;

export default () => {
  const favicon = document.getElementById("favicon");

  if (!("OffscreenCanvas" in window)) {
    return
  }
  const worker = new Worker('/assets/worker.js');
  const offcanvas = new OffscreenCanvas(ICON_SIZE, ICON_SIZE);
  worker.postMessage(offcanvas, [offcanvas]);

  const canvas = document.createElement('canvas');
  canvas.width = ICON_SIZE;
  canvas.height = ICON_SIZE;
  const ctx = canvas.getContext('2d');

  worker.onmessage = ({ data }) => {
    if (window.playState !== "playing") {
      return;
    }
    ctx.clearRect(0, 0, ICON_SIZE, ICON_SIZE);
    ctx.drawImage(data, 0, 0);
    favicon.href = canvas.toDataURL();
  }
}
