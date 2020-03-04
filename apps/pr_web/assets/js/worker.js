import { ICON_SIZE } from "./favicon";

const WHITE = "#ffffff";
const CYAN = "#32fad7";
const PINK = "#fc267a";

let y1 = ICON_SIZE;
let y2 = ICON_SIZE;
let y3 = ICON_SIZE;

onmessage = (evt) => {
  const canvas = evt.data;
  const ctx = canvas.getContext("2d");

  function drawBar(ctx, x, y, color) {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, 8, ICON_SIZE - y);
  }

  function drawFrame() {
    ctx.clearRect(0, 0, ICON_SIZE, ICON_SIZE);

    drawBar(ctx, 0, y1, WHITE);
    drawBar(ctx, 12, y2, PINK);
    drawBar(ctx, 24, y3, CYAN);

    postMessage(canvas.transferToImageBitmap());
  }

  function incrementFrame() {
    const time = new Date().getMilliseconds();
    const step = time / 1000;
    const rad = Math.PI * 2 * step;
    y1 = Math.floor(Math.sin(rad - Math.PI / 1) * ICON_SIZE / 2) + (ICON_SIZE /2);
    y2 = Math.floor(Math.sin(rad - Math.PI / 2) * ICON_SIZE / 2) + (ICON_SIZE /2);
    y3 = Math.floor(Math.sin(rad - Math.PI / 3) * ICON_SIZE / 2) + (ICON_SIZE /2);

    drawFrame();
    setTimeout(incrementFrame, 200);
  }

  incrementFrame();
};
