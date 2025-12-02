////
//// 📡 Gleam UI router library
////
//// The vanilla router library to SPA
////

import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

import gbr/js/jscore
import gbr/js/jsdocument
import gbr/js/jselement
import gbr/js/jsevent
import gbr/js/jsglobal
import gbr/js/jshistory

// Alias
//

type Config =
  UUIRouterConfig

type OnUriChange =
  fn(uri.Uri) -> Nil

/// Router config type
///
/// - prefent_default: If is true prevent default behavior on link
/// - use_hash: If true use `uri.Uri.fragment`, or hash, to match item from uri
/// > This option set to true if you app is SPA
///
pub opaque type UUIRouterConfig {
  UIRouterConfig(use_hash: Bool, prevent_default: Bool)
}

/// Get current windown location href
///
pub fn current() -> Option(uri.Uri) {
  jscore.global()
  |> jscore.get_object_inner_key("location", "href")
  |> parse_href()
}

/// Setup router to manage state on uri changes
///
/// This function setup events:
///
/// - window.onclick: User click on window and check if anchor is clicked
///   - https://developer.mozilla.org/en-US/docs/Web/API/Element/click_event
/// - window.popstate: User or code change history entry
///   - https://developer.mozilla.org/en-US/docs/Web/API/Window/popstate_event
///
/// With callback that is executed on uri is change
///
/// Args:
///
/// - config: Router config type
/// - cb: Callback function that receive `uri.Uri`
///
pub fn on_change(config: Option(Config), cb: OnUriChange) -> Nil {
  let config =
    config
    |> option.unwrap(const_config_default)

  // if use hash, prevent default browser reload and hash scroll
  let config = case config.use_hash {
    False -> config
    True -> cfg_prevent_default(config, True)
  }

  let _ = onload(config, Some(cb))
  let _ = onhash(config, Some(cb))
  let _ = onpopstate(config, Some(cb))
  let _ = onclick(config, Some(cb))
}

// PRIVATE
//

const const_config_default = UIRouterConfig(
  prevent_default: False,
  use_hash: False,
)

/// Set on click window event to capture click into anchor or wrapper anchor elements
///
/// - config: Router config type
/// - dispatch: Callback executed on uri is change, if `option.Some`
///
fn onclick(config, dispatch) -> Nil {
  let UIRouterConfig(prevent_default:, ..) = config

  use event <- jsglobal.add_event_listener("click")

  let _ = jsevent.prevent_default(event)

  let target = Some(jsevent.target(event))
  let anchor =
    find_anchor(target)
    |> get_anchor_href()
    |> parse_href()

  case anchor {
    None -> Nil
    Some(anchor) -> {
      // eager return
      use <- bool.guard(is_external(anchor), do_dispatch(dispatch, anchor))

      // history push state
      let _ =
        uri.to_string(anchor)
        |> jshistory.push()

      // request animation to uri hash scroll
      let _ = request_scroll(anchor, prevent_default)

      // dispatch on uri change
      do_dispatch(dispatch, anchor)
    }
  }
}

/// Set on popstate window event to capture history changes
///
/// - config: Router config type
/// - dispatch: Callback executed on uri is change, if `option.Some`
///
fn onpopstate(config, dispatch) -> Nil {
  on_(config, dispatch, "popstate")
}

fn onload(config, dispatch) -> Nil {
  on_(config, dispatch, "load")
}

fn onhash(config, dispatch) -> Nil {
  on_(config, dispatch, "hashchange")
}

fn on_(config, dispatch, onevent) -> Nil {
  let UIRouterConfig(prevent_default:, ..) = config

  use event <- jsglobal.add_event_listener(onevent)

  let _ = jsevent.prevent_default(event)

  let href =
    current()
    |> option.unwrap(uri.empty)

  let _ = request_scroll(href, prevent_default)

  do_dispatch(dispatch, href)
}

/// Set router config prevent default
///
fn cfg_prevent_default(cfg, prevent_default) {
  UIRouterConfig(..cfg, prevent_default:)
}

/// Request animation to scroll default browser behavior
///
/// - href: Uri current
/// - prevent_default: If true, cancel not execute
///
fn request_scroll(href, prevent_default) {
  // If router config prevent default is True, then
  //   disable the default browser behavior to scroll until uri hash
  use <- bool.guard(prevent_default, None)

  // Simulate default browser behavior
  // Scrolling to hash href if exists
  request_animation_frame(href)
  |> Some()
}

/// Request scroll to top page or hash element, if exists
///
/// - href: Uri that contains fragment '#/' hash part url
/// - prevent_default:
///
/// Returns
///
/// - RequestID: To cancel this animation request
///
fn request_animation_frame(href: uri.Uri) -> jscore.RequestID {
  // js global request animation frame
  use _rate <- jsglobal.request_animation_frame()

  let hash = get_hash(href)

  case hash {
    None -> jsglobal.scroll_to(0, 0)
    Some(hash) -> {
      use _ <- function.tap(Nil)
      use el <- result.map(jsdocument.get_element_by_id(hash))

      jselement.scroll_into_view(el)
    }
  }
}

/// Get hash from fragment uri
///
/// - href: Uri to get hash fragment
///
fn get_hash(href: uri.Uri) -> Option(String) {
  use hash <- option.then(href.fragment)
  let is_empty = string.length(hash) > 1

  case is_empty {
    True -> None
    False ->
      string.slice(hash, 0, 1)
      |> Some()
  }
}

/// Parse window location href string to uri.Uri
///
/// - href: String representation of uri
///
fn parse_href(href: Option(String)) -> Option(uri.Uri) {
  use href <- option.then(href)

  let is_empty = string.is_empty(href)

  case is_empty {
    True -> current()
    False ->
      uri.parse(href)
      |> result.map_error(fn(_) { io.println_error("Error router parsing uri") })
      |> option.from_result
  }
}

/// Convert `decode.DecodeError` to string
///
fn to_string_decode_errors(errors: List(decode.DecodeError)) {
  use dec_error <- list.map(errors)

  "Expected: " <> dec_error.expected <> "Found: " <> dec_error.found
}

/// Get anchor href from anchor js element
///
fn get_anchor_href(anchor: Option(dynamic.Dynamic)) -> Option(String) {
  use anchor <- option.then(anchor)

  anchor
  |> decode.run(decode.at(["href"], decode.string))
  |> result.map_error(to_string_decode_errors)
  |> result.map_error(string.join(_, "\n"))
  |> result.map_error(io.println_error)
  |> option.from_result()
}

/// Find anchor from target element `event.target`
///
/// - target: Option to target element, if None nothing is done
///
fn find_anchor(target: Option(dynamic.Dynamic)) -> Option(dynamic.Dynamic) {
  use target <- option.then(target)

  let parent =
    target
    |> decode.run(decode.at(["parentElement"], decode.dynamic))
    |> result.map_error(to_string_decode_errors)
    |> result.map_error(string.join(_, "\n"))
    |> result.map_error(io.println_error)
    |> option.from_result()

  let tag_name =
    target
    |> decode.run(decode.at(["tagName"], decode.string))
    |> result.map_error(to_string_decode_errors)
    |> result.map_error(string.join(_, "\n"))
    |> result.map_error(io.println_error)
    |> option.from_result()

  use tag_name <- option.then(tag_name)

  use <- bool.guard(tag_name == "BODY", None)

  use <- bool.guard(tag_name == "A", Some(target))

  find_anchor(parent)
}

/// Helper to execute callback on uri is change
///
/// - dispatch: Option callback function
/// - href: Uri has been change
///
fn do_dispatch(dispatch, href) {
  case dispatch {
    Some(dispatch) -> dispatch(href)
    None -> Nil
  }
}

fn is_external(anchor: uri.Uri) {
  let host =
    jscore.global()
    |> jscore.get_object_inner_key("location", "host")

  use <- bool.guard(option.is_none(host), True)
  let assert Some(host) = host

  let origin_host = {
    use hostname <- option.then(anchor.host)
    use port <- option.map(anchor.port)

    hostname <> ":" <> int.to_string(port)
  }

  case origin_host {
    Some(origin_host) -> host != origin_host
    None -> True
  }
}
