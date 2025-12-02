/**
 * @packageDocumentation
 * @module index
 *
 * 📡 Gleam UI router library
 *
 * The vanilla router library to SPA
 */

import {
  item,
  match,
  current,
  on_router,
  on_change,
} from "./gbr/ui/router.gleam";

/**
 * Router current href
 *
 * Function not call gleam code but _is the same code_
 */
export const currentHref = () => {
  new URL(window.location.href)
}

/**
 * Router setup routes and callback to match them
 */
export const onRouter = on_router

/**
 * Router current href
 */
export const onChange = on_change

/**
 * Router new route item
 */
export const itemNew = item

/**
 * Router new route item
 */
export const itemMatch = match
