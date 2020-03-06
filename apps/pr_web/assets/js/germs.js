import HM from 'heatmap.js';

export default (socket) => {
  const domElement = document.getElementById("content");
  const channel = socket.channel("mouse:position", {})
  const heatmap = HM.create({
    container: domElement,
    raidius: 50
  });

  channel.join().receive("error", resp => { console.log("Unable to join coronavirus channel", resp) });
  channel.on("mouse:position", ({x, y}) => {
    heatmap.addData({ x, y, value: 1 });
  });

  domElement.addEventListener('mousemove', throttle(({clientX: x, clientY: y}) => {
    console.log(x, y);
    channel.push("mouse:position", {x, y}, 100);
  }, 100));
};

function throttle(func, wait, options) {
  var context, args, result;
  var timeout = null;
  var previous = 0;
  if (!options) options = {};
  var later = function() {
    previous = options.leading === false ? 0 : Date.now();
    timeout = null;
    result = func.apply(context, args);
    if (!timeout) context = args = null;
  };
  return function() {
    var now = Date.now();
    if (!previous && options.leading === false) previous = now;
    var remaining = wait - (now - previous);
    context = this;
    args = arguments;
    if (remaining <= 0 || remaining > wait) {
      if (timeout) {
        clearTimeout(timeout);
        timeout = null;
      }
      previous = now;
      result = func.apply(context, args);
      if (!timeout) context = args = null;
    } else if (!timeout && options.trailing !== false) {
      timeout = setTimeout(later, remaining);
    }
    return result;
  };
};

