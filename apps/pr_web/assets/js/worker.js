const ICON_SIZE = 32;

console.log("Hi im worker");

onmessage = async (evt) => {
  const canvas = evt.data;
  const ctx = canvas.getContext("2d");
  drawBar(ctx, 0, "#ffffff", 1, 0, ICON_SIZE, 1, ICON_SIZE / 4);
  drawBar(ctx, 12, "#6efcf1", 1.5, 0, ICON_SIZE - 10, -1, 0);
  drawBar(ctx, 24, "#fc267a", 1.25, 0, ICON_SIZE, 1, ICON_SIZE / 2);

  function drawBar (ctx, x, color, rate, min, max, direction, delta) {
    const y = Math.floor(delta);
    ctx.fillStyle = color;
    ctx.fillRect(x, y, 8, ICON_SIZE - y);
    favicon.href = canvas.toDataURL("image/png");

    window.requestAnimationFrame(() => {
      ctx.clearRect(x, y, 8, ICON_SIZE - y);

      if (1 || canvas.dataset.playback === "active") {
        const nextDirection = delta > max ? -1 : delta < min ? 1 : direction;
        const nextDelta = direction > 0 ? delta + rate : delta - rate;
        drawBar(ctx, x, color, rate, min, max, nextDirection, nextDelta);
      } else {
        drawBar(ctx, x, color, rate, min, max, direction, delta);
      }
    });
  }
};
