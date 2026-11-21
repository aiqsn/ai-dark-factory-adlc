// Hidden test for the golden spec: copied into test/ only after the agent has finished.
import { test } from "node:test";
import assert from "node:assert/strict";
import { search } from "../src/index.js";

test("golden: at most 3 results", () => assert.ok(search("e").length <= 3));
test("golden: name matches rank above tag-only matches", () => {
  const ids = search("waterproof").map((p) => p.id);
  assert.deepEqual(ids, [3, 5]);                       // both match by tag; 3 has it in its name
});
test("golden: blank-free queries keep working", () => assert.deepEqual(search("running").map((p) => p.id), [1, 2, 4]));
