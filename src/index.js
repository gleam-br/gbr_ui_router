/**
 * @packageDocumentation
 * @module index
 *
 * 📡 Gleam UI router library
 *
 * The vanilla router library to SPA
 */

import {
  main,
  setup,
  route,
  routes,
  current,
  on_uri_change,
} from "./gbr/ui/router.gleam";

main()

/**
 * Router current href
 *
 * Function not call gleam code but _is the same code_
 */
export const current = () => {
  new URL(window.location.href)
}

/**
 * Router setup without callback on uri change
 */
export const setup = setup

/**
 * Router new route item
 */
export const route = route

/**
 * Router setup routes and callback to match them
 */
export const routes = routes

/**
 * Router current href
 */
export const onUriChange = on_uri_change
