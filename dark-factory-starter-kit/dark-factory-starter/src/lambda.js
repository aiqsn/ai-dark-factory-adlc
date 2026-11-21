// Runs the same app on AWS Lambda behind a function URL (payload format 2.0).
// Only used by the optional deploy-aws workflow; Cloudflare uses src/index.js directly.
import { readFileSync } from "node:fs";
import worker from "./index.js";

const GIT_SHA = (() => {
  try {
    return readFileSync(new URL("../VERSION", import.meta.url), "utf8").trim();
  } catch {
    return "dev";
  }
})();

export async function handler(event) {
  const method = event.requestContext?.http?.method ?? "GET";
  const host = event.headers?.host ?? "lambda.local";
  const query = event.rawQueryString ? `?${event.rawQueryString}` : "";
  const hasBody = event.body && method !== "GET" && method !== "HEAD";
  const body = hasBody ? (event.isBase64Encoded ? Buffer.from(event.body, "base64") : event.body) : undefined;

  const request = new Request(`https://${host}${event.rawPath ?? "/"}${query}`, {
    method,
    headers: event.headers ?? {},
    body,
  });
  const response = await worker.fetch(request, { GIT_SHA });
  return {
    statusCode: response.status,
    headers: Object.fromEntries(response.headers),
    body: await response.text(),
  };
}
