/**
 * @packageDocumentation
 * @module index
 *
 * 📡 Gleam UI router library
 *
 * The vanilla router library to SPA
 */

import {
  setup,
  route,
  routes,
  on_uri_change,
} from "./gbr/ui/router.gleam";

//import * as navigation from "./gbr/ui/router/navigation.gleam"
//navigation.main()

/**
 * Router current href
 *
 * Function not call gleam code but _is the same code_
 */
export const currentUrl = () => {
  new URL(window.location.href)
}

/**
 * Router setup without callback on uri change
 */
export const routerSetup = setup

/**
 * Router setup routes and callback to match them
 */
export const routerSetupRoutes = routes

/**
 * Router new route item
 */
export const routerNewRoute = route

/**
 * Router current href
 */
export const onUrlChange = on_uri_change
