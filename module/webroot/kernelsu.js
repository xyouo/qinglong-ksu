// Minimal local copy of the official KernelSU WebUI bridge. Keeping this file
// local avoids unresolved bare npm imports in Android WebView.
let callbackCounter = 0;

function callbackName(prefix) {
  return `${prefix}_${Date.now()}_${callbackCounter++}`;
}

export function exec(command, options = {}) {
  return new Promise((resolve, reject) => {
    const name = callbackName("exec");
    window[name] = (errno, stdout, stderr) => {
      delete window[name];
      resolve({ errno, stdout, stderr });
    };
    try {
      if (typeof ksu === "undefined" || typeof ksu.exec !== "function") {
        throw new Error("当前模块管理器不支持 KernelSU WebUI API");
      }
      ksu.exec(command, JSON.stringify(options), name);
    } catch (error) {
      delete window[name];
      reject(error);
    }
  });
}
