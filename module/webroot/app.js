import { exec } from "./kernelsu.js";

const ql = "/data/adb/modules/qinglong_ksu/bin/ql";
const keys = ["QL_PORT", "TZ", "DNS", "BOOT_DELAY", "AUTO_START"];
const $ = (id) => document.getElementById(id);

function notify(message, error = false) {
  const el = $("notice");
  el.textContent = message;
  el.className = error ? "show error" : "show";
  setTimeout(() => (el.className = ""), 2600);
}

async function run(command) {
  const result = await exec(command);
  if (result.errno !== 0) throw new Error(result.stderr || result.stdout || `errno ${result.errno}`);
  return result.stdout.trim();
}

async function refresh() {
  try {
    $("status").textContent = await run(`${ql} status`);
    for (const key of keys) {
      const value = await run(`${ql} config get ${key}`);
      if (key === "AUTO_START") $(key).checked = value === "1";
      else $(key).value = value;
    }
  } catch (error) {
    $("status").textContent = `读取失败：${error.message}`;
    notify(error.message, true);
  }
}

async function setConfig(key, value) {
  const encoded = btoa(unescape(encodeURIComponent(value)));
  return run(`printf %s '${encoded}' | base64 -d | ${ql} config set ${key} -`);
}

async function save() {
  try {
    $("save").disabled = true;
    for (const key of keys) {
      const value = key === "AUTO_START" ? ($(key).checked ? "1" : "0") : $(key).value.trim();
      await setConfig(key, value);
    }
    await run(`${ql} restart`);
    notify("配置已保存，青龙已重启");
    await refresh();
  } catch (error) {
    notify(error.message, true);
  } finally {
    $("save").disabled = false;
  }
}

async function showLogs() {
  try {
    $("log").textContent = await run(`${ql} logs 120`);
  } catch (error) {
    $("log").textContent = error.message;
  }
}

document.querySelectorAll("[data-action]").forEach((button) => {
  button.addEventListener("click", async () => {
    try {
      button.disabled = true;
      await run(`${ql} ${button.dataset.action}`);
      notify("操作完成");
      await refresh();
      await showLogs();
    } catch (error) {
      notify(error.message, true);
    } finally {
      button.disabled = false;
    }
  });
});

$("refresh").addEventListener("click", refresh);
$("logs").addEventListener("click", showLogs);
$("save").addEventListener("click", save);
$("openPanel").addEventListener("click", () => {
  location.href = `http://127.0.0.1:${$("QL_PORT").value}`;
});

await refresh();
await showLogs();
