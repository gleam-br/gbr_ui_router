// Serving ./dist/index.html on localhost:3000
import { join } from "path"
import gleam from "bun-plugin-gleam";

const pathIndex = join(".", "bin", "index.html")
const pathJs = join(".", "dist", "index.js")
const index = Bun.file(pathIndex)
const js = Bun.file(pathJs)
const port = 3000
const hostname = "0.0.0.0"

Bun.serve({
  port,
  hostname,
  plugins: [gleam({ log: "debug", force: true })],
  fetch(req) {
    if (req.url.endsWith(".js")) {
      return new Response(js)
    }
    return new Response(index)
  },
  error(err) {
    console.error("Server error:", err);
    return new Response("Internal Server Error", { status: 500 });
  },
})

console.log(`Serving ${pathIndex} on 'http://${hostname}:${port}'!`);
