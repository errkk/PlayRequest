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
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vYXNzZXRzL2pzL2Zhdmljb24uanMiLCAiLi4vLi4vLi4vYXNzZXRzL2pzL3dvcmtlci5qcyJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiZXhwb3J0IGNvbnN0IElDT05fU0laRSA9IDMyO1xuXG5leHBvcnQgZGVmYXVsdCAoKSA9PiB7XG4gIGNvbnN0IGZhdmljb24gPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChcImZhdmljb25cIik7XG5cbiAgY29uc3Qgd29ya2VyID0gbmV3IFdvcmtlcignL2Fzc2V0cy93b3JrZXIuanMnKTtcbiAgY29uc3Qgb2ZmY2FudmFzID0gbmV3IE9mZnNjcmVlbkNhbnZhcyhJQ09OX1NJWkUsIElDT05fU0laRSk7XG4gIHdvcmtlci5wb3N0TWVzc2FnZShvZmZjYW52YXMsIFtvZmZjYW52YXNdKTtcblxuICBjb25zdCBjYW52YXMgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCdjYW52YXMnKTtcbiAgY2FudmFzLndpZHRoID0gSUNPTl9TSVpFO1xuICBjYW52YXMuaGVpZ2h0ID0gSUNPTl9TSVpFO1xuICBjb25zdCBjdHggPSBjYW52YXMuZ2V0Q29udGV4dCgnMmQnKTtcblxuICB3b3JrZXIub25tZXNzYWdlID0gKHtkYXRhfSkgPT4ge1xuICAgIGlmICh3aW5kb3cucGxheVN0YXRlICE9PSBcInBsYXlpbmdcIikge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBjdHguY2xlYXJSZWN0KDAsIDAsIElDT05fU0laRSwgSUNPTl9TSVpFKTtcbiAgICBjdHguZHJhd0ltYWdlKGRhdGEsIDAsIDApO1xuICAgIGZhdmljb24uaHJlZiA9IGNhbnZhcy50b0RhdGFVUkwoKTtcbiAgfVxufVxuIiwgImltcG9ydCB7IElDT05fU0laRSB9IGZyb20gXCIuL2Zhdmljb25cIjtcblxuY29uc3QgV0hJVEUgPSBcIiNmZmZmZmZcIjtcbmNvbnN0IENZQU4gPSBcIiMzMmZhZDdcIjtcbmNvbnN0IFBJTksgPSBcIiNmYzI2N2FcIjtcblxubGV0IHkxID0gSUNPTl9TSVpFO1xubGV0IHkyID0gSUNPTl9TSVpFO1xubGV0IHkzID0gSUNPTl9TSVpFO1xuXG5vbm1lc3NhZ2UgPSAoZXZ0KSA9PiB7XG4gIGNvbnN0IGNhbnZhcyA9IGV2dC5kYXRhO1xuICBjb25zdCBjdHggPSBjYW52YXMuZ2V0Q29udGV4dChcIjJkXCIpO1xuXG4gIGZ1bmN0aW9uIGRyYXdCYXIoY3R4LCB4LCB5LCBjb2xvcikge1xuICAgIGN0eC5maWxsU3R5bGUgPSBjb2xvcjtcbiAgICBjdHguZmlsbFJlY3QoeCwgeSwgOCwgSUNPTl9TSVpFIC0geSk7XG4gIH1cblxuICBmdW5jdGlvbiBkcmF3RnJhbWUoKSB7XG4gICAgY3R4LmNsZWFyUmVjdCgwLCAwLCBJQ09OX1NJWkUsIElDT05fU0laRSk7XG5cbiAgICBkcmF3QmFyKGN0eCwgMCwgeTEsIFdISVRFKTtcbiAgICBkcmF3QmFyKGN0eCwgMTIsIHkyLCBQSU5LKTtcbiAgICBkcmF3QmFyKGN0eCwgMjQsIHkzLCBDWUFOKTtcblxuICAgIHBvc3RNZXNzYWdlKGNhbnZhcy50cmFuc2ZlclRvSW1hZ2VCaXRtYXAoKSk7XG4gIH1cblxuICBmdW5jdGlvbiBpbmNyZW1lbnRGcmFtZSgpIHtcbiAgICBjb25zdCB0aW1lID0gbmV3IERhdGUoKS5nZXRNaWxsaXNlY29uZHMoKTtcbiAgICBjb25zdCBzdGVwID0gdGltZSAvIDEwMDA7XG4gICAgY29uc3QgcmFkID0gTWF0aC5QSSAqIDIgKiBzdGVwO1xuICAgIHkxID0gTWF0aC5mbG9vcihNYXRoLnNpbihyYWQgLSBNYXRoLlBJIC8gMSkgKiBJQ09OX1NJWkUgLyAyKSArIChJQ09OX1NJWkUgLzIpO1xuICAgIHkyID0gTWF0aC5mbG9vcihNYXRoLnNpbihyYWQgLSBNYXRoLlBJIC8gMikgKiBJQ09OX1NJWkUgLyAyKSArIChJQ09OX1NJWkUgLzIpO1xuICAgIHkzID0gTWF0aC5mbG9vcihNYXRoLnNpbihyYWQgLSBNYXRoLlBJIC8gMykgKiBJQ09OX1NJWkUgLyAyKSArIChJQ09OX1NJWkUgLzIpO1xuXG4gICAgZHJhd0ZyYW1lKCk7XG4gICAgc2V0VGltZW91dChpbmNyZW1lbnRGcmFtZSwgMjAwKTtcbiAgfVxuXG4gIGluY3JlbWVudEZyYW1lKCk7XG59O1xuIl0sCiAgIm1hcHBpbmdzIjogIjs7QUFBTyxNQUFNLFlBQVk7OztBQ0V6QixNQUFNLFFBQVE7QUFDZCxNQUFNLE9BQU87QUFDYixNQUFNLE9BQU87QUFFYixNQUFJLEtBQUs7QUFDVCxNQUFJLEtBQUs7QUFDVCxNQUFJLEtBQUs7QUFFVCxjQUFZLENBQUMsUUFBUTtBQUNuQixVQUFNLFNBQVMsSUFBSTtBQUNuQixVQUFNLE1BQU0sT0FBTyxXQUFXO0FBRTlCLHFCQUFpQixNQUFLLEdBQUcsR0FBRyxPQUFPO0FBQ2pDLFdBQUksWUFBWTtBQUNoQixXQUFJLFNBQVMsR0FBRyxHQUFHLEdBQUcsWUFBWTtBQUFBO0FBR3BDLHlCQUFxQjtBQUNuQixVQUFJLFVBQVUsR0FBRyxHQUFHLFdBQVc7QUFFL0IsY0FBUSxLQUFLLEdBQUcsSUFBSTtBQUNwQixjQUFRLEtBQUssSUFBSSxJQUFJO0FBQ3JCLGNBQVEsS0FBSyxJQUFJLElBQUk7QUFFckIsa0JBQVksT0FBTztBQUFBO0FBR3JCLDhCQUEwQjtBQUN4QixZQUFNLE9BQU8sSUFBSSxPQUFPO0FBQ3hCLFlBQU0sT0FBTyxPQUFPO0FBQ3BCLFlBQU0sTUFBTSxLQUFLLEtBQUssSUFBSTtBQUMxQixXQUFLLEtBQUssTUFBTSxLQUFLLElBQUksTUFBTSxLQUFLLEtBQUssS0FBSyxZQUFZLEtBQU0sWUFBVztBQUMzRSxXQUFLLEtBQUssTUFBTSxLQUFLLElBQUksTUFBTSxLQUFLLEtBQUssS0FBSyxZQUFZLEtBQU0sWUFBVztBQUMzRSxXQUFLLEtBQUssTUFBTSxLQUFLLElBQUksTUFBTSxLQUFLLEtBQUssS0FBSyxZQUFZLEtBQU0sWUFBVztBQUUzRTtBQUNBLGlCQUFXLGdCQUFnQjtBQUFBO0FBRzdCO0FBQUE7IiwKICAibmFtZXMiOiBbXQp9Cg==
