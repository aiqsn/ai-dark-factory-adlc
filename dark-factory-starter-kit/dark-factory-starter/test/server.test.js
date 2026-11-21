// The container entry point (src/server.js) must serve the same app as the Worker.
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";

test("container server serves /healthz, /version and search", async (t) => {
  const port = 18000 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ["src/server.js"], { env: { ...process.env, PORT: String(port), GIT_SHA: "test-sha" } });
  t.after(() => child.kill());
  await new Promise((resolve, reject) => {
    child.stdout.on("data", (d) => String(d).includes("listening") && resolve());
    child.on("exit", (code) => reject(new Error(`server exited with ${code}`)));
  });
  const base = `http://127.0.0.1:${port}`;
  assert.equal(await (await fetch(`${base}/healthz`)).text(), "ok");
  assert.equal(await (await fetch(`${base}/version`)).text(), "test-sha");
  const res = await fetch(`${base}/api/search?q=running`);
  assert.equal(res.status, 200);
  assert.ok((await res.json()).results.length > 0);
});
