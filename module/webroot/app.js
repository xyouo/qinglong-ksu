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

async function accountValue(action, value) {
  const encoded = btoa(unescape(encodeURIComponent(value)));
  return run(`printf %s '${encoded}' | base64 -d | ${ql} account ${action} -`);
}

async function save() {
  try {
    $("save").disabled = true;
    for (const key of keys) {
      const value = key === "AUTO_START" ? ($(key).checked ? "1" : "0") : $(key).value.trim();
      await setConfig(key, value);
    }
    await run(`${ql} restart-async`);
    notify("配置已保存，正在后台重启青龙");
    setTimeout(refresh, 4000);
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
      const action = button.dataset.action === "restart" ? "restart-async" : button.dataset.action;
      await run(`${ql} ${action}`);
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
$("setUsername").addEventListener("click", async () => {
  const value = $("newUsername").value.trim();
  if (!value) return notify("请输入新用户名", true);
  try {
    await accountValue("set-username", value);
    $("newUsername").value = "";
    notify("用户名修改成功");
  } catch (error) {
    notify(error.message, true);
  }
});
$("setPassword").addEventListener("click", async () => {
  const value = $("newPassword").value;
  if (value.length < 6) return notify("密码至少需要 6 位", true);
  try {
    await accountValue("set-password", value);
    $("newPassword").value = "";
    notify("密码修改成功");
  } catch (error) {
    notify(error.message, true);
  }
});
$("resetLock").addEventListener("click", async () => {
  try {
    await run(`${ql} account reset-lock`);
    notify("登录失败次数已重置");
  } catch (error) {
    notify(error.message, true);
  }
});
$("disable2fa").addEventListener("click", async () => {
  if (!confirm("确定关闭青龙两步验证吗？")) return;
  try {
    await run(`${ql} account disable-2fa`);
    notify("两步验证已关闭");
  } catch (error) {
    notify(error.message, true);
  }
});
$("openPanel").addEventListener("click", () => {
  location.href = `http://127.0.0.1:${$("QL_PORT").value}`;
});

await refresh();
await showLogs();
