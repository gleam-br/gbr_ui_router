import { defineConfig } from "bunup";
import { exports, unused } from 'bunup/plugins';

import gleam from "bun-plugin-gleam";

export default defineConfig({
  entry: ["src/index.js"],
  target: "node",
  format: ["esm"],
  sourcemap: "linked",
  minify: true,
  dts: false,
  plugins: [gleam({ log: 'debug', force: true }), exports(), unused()]
});
