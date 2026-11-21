// A tiny product-search API on Cloudflare Workers: the sample app the factory builds on.
// Replace it with your own app; keep /healthz and /version, which the deploy probes rely on.

// Stryker disable all: catalogue data, not logic, so mutating it only adds noise
export const PRODUCTS = [
  { id: 1, name: "Trail running shoes", tags: ["running", "shoes", "trail"] },
  { id: 2, name: "Road running shoes", tags: ["running", "shoes", "road"] },
  { id: 3, name: "Waterproof hiking boots", tags: ["hiking", "boots", "waterproof"] },
  { id: 4, name: "Merino running socks", tags: ["running", "socks", "merino"] },
  { id: 5, name: "Lightweight rain jacket", tags: ["jacket", "rain", "waterproof"] },
  { id: 6, name: "Insulated water bottle", tags: ["bottle", "hydration"] },
];
// Stryker restore all

// Returns products whose name or tags contain every word of the query, ignoring case.
export function search(query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  return PRODUCTS.filter((p) => {
    const haystack = [p.name, ...p.tags].join(" ").toLowerCase();
    return words.every((w) => haystack.includes(w));
  });
}

// Stryker disable next-line all: page copy
const HOME = `<!doctype html><meta charset="utf-8"><title>Dark factory sample</title>
<h1>Dark factory sample app</h1><p>Try <a href="/api/search?q=running">/api/search?q=running</a>.</p>`;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/healthz") return new Response("ok");
    if (url.pathname === "/version") return new Response(env?.GIT_SHA ?? "dev");

    if (url.pathname === "/api/search") {
      const q = (url.searchParams.get("q") ?? "").trim();
      if (!q) return Response.json({ error: "missing q" }, { status: 400 });
      return Response.json({ query: q, results: search(q) });
    }

    if (url.pathname === "/") {
      return new Response(HOME, { headers: { "content-type": "text/html; charset=utf-8" } });
    }

    return new Response("not found", { status: 404 });
  },
};
