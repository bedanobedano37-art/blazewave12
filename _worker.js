const WINDOW = 15;
const LIMIT = 40;
const FALLBACK_SECRET = "";
const FALLBACK_LOAD_KEY = "";

const TOOLS = /(curl|wget|python|aiohttp|httpx|urllib|node-fetch|axios|undici|go-http|libwww|postman|insomnia|httpie|httpclient|php|ruby|scrapy|powershell|reqwest|guzzle|deno|bun\/|headless|phantom|puppeteer|playwright|selenium|spider|crawl)/i;
const BOTS = /(bot\b)/i;

async function sign(secret, msg) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const buf = await crypto.subtle.sign("HMAC", key, enc.encode(msg));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function same(a, b) {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

function isDocument(request) {
  const dest = request.headers.get("sec-fetch-dest");
  const accept = request.headers.get("accept") || "";
  return dest === "document" || (!dest && accept.includes("text/html"));
}

function hasBrowserHeaders(request) {
  const h = request.headers;
  return !!(h.get("origin") || h.get("referer") || h.get("sec-fetch-dest") || h.get("sec-fetch-mode") || h.get("sec-fetch-site") || h.get("sec-ch-ua"));
}

function blockedLoader(request, env) {
  const ua = request.headers.get("user-agent") || "";
  if (TOOLS.test(ua) || BOTS.test(ua)) return true;
  if (hasBrowserHeaders(request)) return true;
  if (env.STRICT === "1" && !/roblox/i.test(ua)) return true;
  return false;
}

async function limited(request, url) {
  const ip = request.headers.get("cf-connecting-ip") || "x";
  const minute = Math.floor(Date.now() / 60000);
  const key = new Request(url.origin + "/__rl/" + ip + "/" + minute);
  const cache = caches.default;
  const hit = await cache.match(key);
  const n = hit ? Number(await hit.text()) + 1 : 1;
  await cache.put(key, new Response(String(n), { headers: { "cache-control": "max-age=90" } }));
  return n > LIMIT;
}

const plain = { "content-type": "text/plain", "cache-control": "no-store", "x-robots-tag": "noindex" };
const dead = () => new Response(null, { status: 404, headers: { "cache-control": "no-store" } });

function secure(res) {
  const out = new Response(res.body, res);
  out.headers.set("x-content-type-options", "nosniff");
  out.headers.set("referrer-policy", "no-referrer");
  out.headers.set("x-frame-options", "DENY");
  out.headers.set("permissions-policy", "camera=(), microphone=(), geolocation=()");
  return out;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const secret = env.SECRET || FALLBACK_SECRET;
    const ua = request.headers.get("user-agent") || "";

    if (url.pathname === "/mainloader") {
      if (isDocument(request)) {
        return Response.redirect(new URL("/protected", url), 302);
      }
      if (blockedLoader(request, env)) return dead();
      if (await limited(request, url)) return dead();
      const ts = Math.floor(Date.now() / 1000);
      const sig = await sign(secret, String(ts));
      const link = url.origin + "/jnk?ts=" + ts + "&sig=" + sig;
      return new Response('loadstring(game:HttpGet("' + link + '"))()', { headers: plain });
    }

    if (url.pathname === "/jnk") {
      if (isDocument(request) || blockedLoader(request, env)) return dead();
      const ts = url.searchParams.get("ts") || "";
      const sig = url.searchParams.get("sig") || "";
      const now = Math.floor(Date.now() / 1000);
      if (!/^\d{10}$/.test(ts) || Math.abs(now - Number(ts)) > WINDOW) return dead();
      const good = await sign(secret, ts);
      if (!same(good, sig)) return dead();
      const cache = caches.default;
      const mark = new Request(url.origin + "/__used/" + sig);
      if (await cache.match(mark)) return dead();
      await cache.put(mark, new Response("1", { headers: { "cache-control": "max-age=300" } }));
      const asset = await env.ASSETS.fetch(new Request(url.origin + "/loader.lua"));
      if (!asset.ok) return dead();
      const loadKey = env.LOAD_KEY || FALLBACK_LOAD_KEY;
      const text = (await asset.text()).replace("YOUR_LOAD_KEY", () => loadKey);
      return new Response(text, { headers: plain });
    }

    if (url.pathname === "/load") {
      if (request.method !== "POST") return dead();
      if (blockedLoader(request, env)) return dead();
      if (await limited(request, url)) return dead();
      let body;
      try { body = await request.json(); } catch (e) { return dead(); }
      const loadKey = env.LOAD_KEY || FALLBACK_LOAD_KEY;
      if (!loadKey || !body || typeof body.file !== "string" || body.auth_key !== loadKey) return dead();
      const file = body.file.replace(/\.\./g, "").replace(/^\/+/, "");
      if (!file || !/^[a-zA-Z0-9_\-/]+\.lua$/.test(file)) return dead();
      const asset = await env.ASSETS.fetch(new Request(url.origin + "/" + file));
      if (!asset.ok) return dead();
      return new Response(await asset.text(), { headers: plain });
    }

    if (/\.lua$/i.test(url.pathname)) return dead();

    if (TOOLS.test(ua) || !ua) return dead();

    if (/\.(png|webp|jpe?g|gif|svg|ico)$/i.test(url.pathname)) {
      const ref = request.headers.get("referer");
      if (ref) {
        let host = "";
        try { host = new URL(ref).host; } catch (e) { host = "x"; }
        if (host !== url.host) return dead();
      }
    }

    return secure(await env.ASSETS.fetch(request));
  },
};
