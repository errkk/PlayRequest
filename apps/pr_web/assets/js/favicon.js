export default () => {
  const favicon = document.getElementById("favicon");
  const canvas = document.getElementById("canvas");
  const worker = new Worker('/js/worker.js');
  const offcanvas = canvas.transferControlToOffscreen();
  worker.onmessage = e => favicon.href = e.data;
  worker.postMessage(offcanvas, [offcanvas]);
}
