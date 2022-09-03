(() => {
  // js/favicon.js
  var ICON_SIZE = 32;

  // js/worker.js
  var WHITE = "#ffffff";
  var CYAN = "#32fad7";
  var PINK = "#fc267a";
  var y1 = ICON_SIZE;
  var y2 = ICON_SIZE;
  var y3 = ICON_SIZE;
  onmessage = (evt) => {
    const canvas = evt.data;
    const ctx = canvas.getContext("2d");
    function drawBar(ctx2, x, y, color) {
      ctx2.fillStyle = color;
      ctx2.fillRect(x, y, 8, ICON_SIZE - y);
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
      const step = time / 1e3;
      const rad = Math.PI * 2 * step;
      y1 = Math.floor(Math.sin(rad - Math.PI / 1) * ICON_SIZE / 2) + ICON_SIZE / 2;
      y2 = Math.floor(Math.sin(rad - Math.PI / 2) * ICON_SIZE / 2) + ICON_SIZE / 2;
      y3 = Math.floor(Math.sin(rad - Math.PI / 3) * ICON_SIZE / 2) + ICON_SIZE / 2;
      drawFrame();
      setTimeout(incrementFrame, 200);
    }
    incrementFrame();
  };
})();
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vYXNzZXRzL2pzL2Zhdmljb24uanMiLCAiLi4vLi4vLi4vYXNzZXRzL2pzL3dvcmtlci5qcyJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiZXhwb3J0IGNvbnN0IElDT05fU0laRSA9IDMyO1xuXG5leHBvcnQgZGVmYXVsdCAoKSA9PiB7XG4gIGNvbnN0IGZhdmljb24gPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChcImZhdmljb25cIik7XG5cbiAgaWYgKCEoXCJPZmZzY3JlZW5DYW52YXNcIiBpbiB3aW5kb3cpKSB7XG4gICAgcmV0dXJuXG4gIH1cbiAgY29uc3Qgd29ya2VyID0gbmV3IFdvcmtlcignL2Fzc2V0cy93b3JrZXIuanMnKTtcbiAgY29uc3Qgb2ZmY2FudmFzID0gbmV3IE9mZnNjcmVlbkNhbnZhcyhJQ09OX1NJWkUsIElDT05fU0laRSk7XG4gIHdvcmtlci5wb3N0TWVzc2FnZShvZmZjYW52YXMsIFtvZmZjYW52YXNdKTtcblxuICBjb25zdCBjYW52YXMgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdjYW52YXMnKTtcbiAgY2FudmFzLndpZHRoID0gSUNPTl9TSVpFO1xuICBjYW52YXMuaGVpZ2h0ID0gSUNPTl9TSVpFO1xuICBjb25zdCBjdHggPSBjYW52YXMuZ2V0Q29udGV4dCgnMmQnKTtcblxuICB3b3JrZXIub25tZXNzYWdlID0gKHsgZGF0YSB9KSA9PiB7XG4gICAgaWYgKHdpbmRvdy5wbGF5U3RhdGUgIT09IFwicGxheWluZ1wiKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuICAgIGN0eC5jbGVhclJlY3QoMCwgMCwgSUNPTl9TSVpFLCBJQ09OX1NJWkUpO1xuICAgIGN0eC5kcmF3SW1hZ2UoZGF0YSwgMCwgMCk7XG4gICAgZmF2aWNvbi5ocmVmID0gY2FudmFzLnRvRGF0YVVSTCgpO1xuICB9XG59XG4iLCAiaW1wb3J0IHsgSUNPTl9TSVpFIH0gZnJvbSBcIi4vZmF2aWNvblwiO1xuXG5jb25zdCBXSElURSA9IFwiI2ZmZmZmZlwiO1xuY29uc3QgQ1lBTiA9IFwiIzMyZmFkN1wiO1xuY29uc3QgUElOSyA9IFwiI2ZjMjY3YVwiO1xuXG5sZXQgeTEgPSBJQ09OX1NJWkU7XG5sZXQgeTIgPSBJQ09OX1NJWkU7XG5sZXQgeTMgPSBJQ09OX1NJWkU7XG5cbm9ubWVzc2FnZSA9IChldnQpID0+IHtcbiAgY29uc3QgY2FudmFzID0gZXZ0LmRhdGE7XG4gIGNvbnN0IGN0eCA9IGNhbnZhcy5nZXRDb250ZXh0KFwiMmRcIik7XG5cbiAgZnVuY3Rpb24gZHJhd0JhcihjdHgsIHgsIHksIGNvbG9yKSB7XG4gICAgY3R4LmZpbGxTdHlsZSA9IGNvbG9yO1xuICAgIGN0eC5maWxsUmVjdCh4LCB5LCA4LCBJQ09OX1NJWkUgLSB5KTtcbiAgfVxuXG4gIGZ1bmN0aW9uIGRyYXdGcmFtZSgpIHtcbiAgICBjdHguY2xlYXJSZWN0KDAsIDAsIElDT05fU0laRSwgSUNPTl9TSVpFKTtcblxuICAgIGRyYXdCYXIoY3R4LCAwLCB5MSwgV0hJVEUpO1xuICAgIGRyYXdCYXIoY3R4LCAxMiwgeTIsIFBJTkspO1xuICAgIGRyYXdCYXIoY3R4LCAyNCwgeTMsIENZQU4pO1xuXG4gICAgcG9zdE1lc3NhZ2UoY2FudmFzLnRyYW5zZmVyVG9JbWFnZUJpdG1hcCgpKTtcbiAgfVxuXG4gIGZ1bmN0aW9uIGluY3JlbWVudEZyYW1lKCkge1xuICAgIGNvbnN0IHRpbWUgPSBuZXcgRGF0ZSgpLmdldE1pbGxpc2Vjb25kcygpO1xuICAgIGNvbnN0IHN0ZXAgPSB0aW1lIC8gMTAwMDtcbiAgICBjb25zdCByYWQgPSBNYXRoLlBJICogMiAqIHN0ZXA7XG4gICAgeTEgPSBNYXRoLmZsb29yKE1hdGguc2luKHJhZCAtIE1hdGguUEkgLyAxKSAqIElDT05fU0laRSAvIDIpICsgKElDT05fU0laRSAvMik7XG4gICAgeTIgPSBNYXRoLmZsb29yKE1hdGguc2luKHJhZCAtIE1hdGguUEkgLyAyKSAqIElDT05fU0laRSAvIDIpICsgKElDT05fU0laRSAvMik7XG4gICAgeTMgPSBNYXRoLmZsb29yKE1hdGguc2luKHJhZCAtIE1hdGguUEkgLyAzKSAqIElDT05fU0laRSAvIDIpICsgKElDT05fU0laRSAvMik7XG5cbiAgICBkcmF3RnJhbWUoKTtcbiAgICBzZXRUaW1lb3V0KGluY3JlbWVudEZyYW1lLCAyMDApO1xuICB9XG5cbiAgaW5jcmVtZW50RnJhbWUoKTtcbn07XG4iXSwKICAibWFwcGluZ3MiOiAiOztBQUFPLE1BQU0sWUFBWTs7O0FDRXpCLE1BQU0sUUFBUTtBQUNkLE1BQU0sT0FBTztBQUNiLE1BQU0sT0FBTztBQUViLE1BQUksS0FBSztBQUNULE1BQUksS0FBSztBQUNULE1BQUksS0FBSztBQUVULGNBQVksQ0FBQyxRQUFRO0FBQ25CLFVBQU0sU0FBUyxJQUFJO0FBQ25CLFVBQU0sTUFBTSxPQUFPLFdBQVc7QUFFOUIscUJBQWlCLE1BQUssR0FBRyxHQUFHLE9BQU87QUFDakMsV0FBSSxZQUFZO0FBQ2hCLFdBQUksU0FBUyxHQUFHLEdBQUcsR0FBRyxZQUFZO0FBQUE7QUFHcEMseUJBQXFCO0FBQ25CLFVBQUksVUFBVSxHQUFHLEdBQUcsV0FBVztBQUUvQixjQUFRLEtBQUssR0FBRyxJQUFJO0FBQ3BCLGNBQVEsS0FBSyxJQUFJLElBQUk7QUFDckIsY0FBUSxLQUFLLElBQUksSUFBSTtBQUVyQixrQkFBWSxPQUFPO0FBQUE7QUFHckIsOEJBQTBCO0FBQ3hCLFlBQU0sT0FBTyxJQUFJLE9BQU87QUFDeEIsWUFBTSxPQUFPLE9BQU87QUFDcEIsWUFBTSxNQUFNLEtBQUssS0FBSyxJQUFJO0FBQzFCLFdBQUssS0FBSyxNQUFNLEtBQUssSUFBSSxNQUFNLEtBQUssS0FBSyxLQUFLLFlBQVksS0FBTSxZQUFXO0FBQzNFLFdBQUssS0FBSyxNQUFNLEtBQUssSUFBSSxNQUFNLEtBQUssS0FBSyxLQUFLLFlBQVksS0FBTSxZQUFXO0FBQzNFLFdBQUssS0FBSyxNQUFNLEtBQUssSUFBSSxNQUFNLEtBQUssS0FBSyxLQUFLLFlBQVksS0FBTSxZQUFXO0FBRTNFO0FBQ0EsaUJBQVcsZ0JBQWdCO0FBQUE7QUFHN0I7QUFBQTsiLAogICJuYW1lcyI6IFtdCn0K
