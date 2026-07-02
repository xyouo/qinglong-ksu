import assert from "node:assert/strict";
import fs from "node:fs";

const source = fs.readFileSync("module/webroot/app.js", "utf8");
const imports = [...source.matchAll(/from\s+["']([^"']+)["']/g)].map((match) => match[1]);

assert(imports.length > 0, "app.js should import the KernelSU bridge");
for (const specifier of imports) {
  assert(
    specifier.startsWith("./") || specifier.startsWith("../"),
    `WebUI contains an unresolved bare import: ${specifier}`,
  );
}

for (const file of ["index.html", "app.js", "style.css", "kernelsu.js"]) {
  assert(fs.existsSync(`module/webroot/${file}`), `missing WebUI asset: ${file}`);
}

for (const action of ["set-username", "set-password", "reset-lock", "disable-2fa"]) {
  assert(source.includes(action), `WebUI is missing account action: ${action}`);
}

assert(source.includes("restart-async"), "WebUI restarts must not block the KernelSU bridge");
assert(!source.includes("await run(`${ql} restart`)"), "WebUI contains a synchronous restart");

console.log("webui tests passed");
