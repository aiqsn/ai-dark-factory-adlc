// Runs the same app as a plain Node HTTP server, for container hosts such as
// Google Cloud Run and Azure Container Apps. Cloudflare uses src/index.js directly.
// The deploy workflow sets GIT_SHA, which /version returns.
import { createServer } from "node:http";
import worker from "./index.js";

const port = Number(process.env.PORT ?? 8080);
const env = { GIT_SHA: process.env.GIT_SHA ?? "dev" };

const server = createServer(async (req, res) => {
  try {
    const host = req.headers.host ?? `localhost:${port}`;
    const hasBody = req.method !== "GET" && req.method !== "HEAD";
    const body = hasBody ? await new Response(req).arrayBuffer() : undefined;
    const request = new Request(`http://${host}${req.url}`, { method: req.method, headers: req.headers, body });
    const response = await worker.fetch(request, env);
    res.writeHead(response.status, Object.fromEntries(response.headers));
    res.end(Buffer.from(await response.arrayBuffer()));
  } catch (err) {
    console.error(err);
    res.writeHead(500, { "content-type": "text/plain" });
    res.end("internal error");
  }
});

server.listen(port, () => console.log(`listening on :${port}`));
for (const sig of ["SIGTERM", "SIGINT"]) process.on(sig, () => server.close(() => process.exit(0)));
