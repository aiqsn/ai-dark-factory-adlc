import { test } from "node:test";
import assert from "node:assert/strict";
import worker, { search } from "../src/index.js";

const call = (path, env = {}) => worker.fetch(new Request(`https://app.test${path}`), env);

test("healthz answers ok", async () => {
  const res = await call("/healthz");
  assert.equal(res.status, 200);
  assert.equal(await res.text(), "ok");
});

test("version returns the deployed git SHA, or dev locally", async () => {
  assert.equal(await (await call("/version", { GIT_SHA: "abc123" })).text(), "abc123");
  assert.equal(await (await call("/version")).text(), "dev");
});

test("search finds products by name or tag, ignoring case", async () => {
  const res = await call("/api/search?q=RUNNING");
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.deepEqual(body.results.map((p) => p.id), [1, 2, 4]);
});

test("search needs every word to match", () => {
  assert.deepEqual(search("running shoes").map((p) => p.id), [1, 2]);
  assert.deepEqual(search("running boots"), []);
});

test("a missing or blank query is a 400 with a clear error", async () => {
  for (const path of ["/api/search", "/api/search?q=", "/api/search?q=%20%20"]) {
    const res = await call(path);
    assert.equal(res.status, 400);
    assert.deepEqual(await res.json(), { error: "missing q" });
  }
});

test("unknown paths are 404", async () => {
  assert.equal((await call("/nope")).status, 404);
});
