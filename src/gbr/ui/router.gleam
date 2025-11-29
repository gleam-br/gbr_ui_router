////
//// 📡 Gleam UI router library
////
//// The vanilla router library to SPA
////

import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/function
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import gleam/uri

import gbr/js/jscore
import gbr/js/jsdocument
import gbr/js/jselement
import gbr/js/jsevent
import gbr/js/jsglobal

/// main testing
pub fn main() -> Nil {
  io.println(">>>>>HERE")
}

// Alias
//

type Options =
  UIRouterOptions

type RouterError =
  UIRouterError

type OnError =
  fn(RouterError) -> Nil

type OnUriChange =
  fn(uri.Uri) -> Nil

type Item(t) =
  UIRouterItem(t)

type Items(t) =
  List(Item(t))

type OnUriItemChange(t) =
  fn(uri.Uri, Item(t)) -> Nil

/// Router error type
///
/// - Not found uri
/// - Unauthorized uri
///
pub opaque type UIRouterError {
  UIRouterItemEmpty
  UIRouterItemUnique
  UIRouterItemRegex(String)
  UIRouterItemNotFound
  // TODO: security router items
  // UIRouterItemUnauthorized
}

/// Router item type representation of one route
///
/// - id: Route identification, best practice use path uri
/// - kind: Route element type will be render this item
///
pub opaque type UIRouterItem(t) {
  UIRouterItem(id: String, kind: t)
}

/// Router options type
///
/// - prefent_default: If is true prevent default behavior on link
/// - use_hash: If true use `uri.Uri.fragment`, or hash, to match item from uri
/// > This option set to true if you app is SPA
/// - match: Route option regex to match with uri path
/// - onerror: Dispatch on router error
///
pub opaque type UIRouterOptions {
  UIRouterOptions(
    prevent_default: Bool,
    use_hash: Bool,
    match: Option(String),
    onerror: Option(OnError),
  )
}

/// Get current windown location href
///
pub fn current() -> Option(uri.Uri) {
  location_href()
  |> option.from_result()
}

///
///
///
pub fn routes(
  items: Items(t),
  cb: OnUriItemChange(t),
  cfg: Option(Options),
) -> Result(Nil, RouterError) {
  // validate route items
  use _ <- result.try(check_items(items))

  // use hash, uri.fragment, instead uri.path
  let use_hash =
    option.map(cfg, fn(options) { options.use_hash })
    |> option.unwrap(False)

  // if use hash, prevent default browser scroll
  let options = case use_hash {
    False -> cfg
    True ->
      option.map(cfg, fn(options) {
        UIRouterOptions(..options, prevent_default: True)
      })
  }

  // if regex match parse it
  let match =
    option.then(cfg, fn(cfg) { cfg.match })
    |> option.map(regexp.from_string)
    |> option.map(fn(res) {
      use cfg <- option.then(cfg)
      use onerror <- option.map(cfg.onerror)
      use err <- result.map_error(res)

      onerror(UIRouterItemRegex(err.error))
    })
    |> option.flatten()
    |> option.map(option.from_result)
    |> option.flatten()

  // trap to return Ok
  use _ <- function.tap(Ok(Nil))

  // on uri change
  use href <- on_uri_change(options)

  // resolve id to found
  let id_to_found = case use_hash {
    // default uses uri.path
    False -> href.path
    True ->
      hash(href)
      // default root path
      |> option.unwrap("/")
  }

  // if regex match
  let item_finder = case match {
    // default use item id to find
    None -> fn(item: Item(t)) { item.id == id_to_found }
    // or use regex match to find
    Some(match) -> fn(_) { regexp.check(match, id_to_found) }
  }

  // exec callback
  case list.find(items, item_finder) {
    Ok(item) -> cb(href, item)
    Error(Nil) ->
      options
      |> option.then(fn(options) { options.onerror })
      |> option.map(fn(onerror) { onerror(UIRouterItemNotFound) })
      |> option.unwrap(Nil)
  }
}

/// New router item representation of one route
///
/// - id: Route identification, best practice use uri
/// - kind: Route element type will be render this item
///
pub fn route(id: String, kind: t) -> Item(t) {
  UIRouterItem(id:, kind:)
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
/// Args:
///
/// - options: Router options type
///
pub fn setup(options: Option(Options)) -> Nil {
  let options =
    options
    |> option.map(function.identity)
    |> option.unwrap(const_options_default)

  let _ = onpopstate(options, None)
  let _ = onclick(options, None)
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
/// - options: Router options type
/// - cb: Callback function that receive `uri.Uri`
///
pub fn on_uri_change(options: Option(Options), cb: OnUriChange) -> Nil {
  let options =
    options
    |> option.map(function.identity)
    |> option.unwrap(const_options_default)

  let _ = onpopstate(options, Some(cb))
  let _ = onclick(options, Some(cb))
}

// PRIVATE
//

const const_options_default = UIRouterOptions(
  prevent_default: False,
  use_hash: False,
  match: None,
  onerror: None,
)

/// Set on click window event to capture click into anchor or wrapper anchor elements
///
/// - options: Router options type
/// - dispatch: Callback executed on uri is change, if `option.Some`
///
fn onclick(options, dispatch) -> Nil {
  let UIRouterOptions(prevent_default:, ..) = options

  use event <- jsglobal.add_event_listener("onclick")

  let target =
    jsevent.target(event)
    |> Some

  let anchor =
    find_anchor(target)
    |> get_anchor_href()
    |> parse_href()
    |> option.from_result()

  case anchor {
    None -> Nil
    Some(anchor) -> {
      let is_internal =
        jscore.global()
        |> jscore.get_object_inner_key("location", "host")
        |> option.map(fn(host) { host == anchor.host })
        |> option.unwrap(False)

      use <- bool.guard(!is_internal, do_dispatch(dispatch, anchor))

      // TODO
      // window.history.pushState({}, "", anchor.path)
      let _ = request_scroll(anchor, prevent_default)

      do_dispatch(dispatch, anchor)
    }
  }
}

/// Set on popstate window event to capture history changes
///
/// - options: Router options type
/// - dispatch: Callback executed on uri is change, if `option.Some`
///
fn onpopstate(options, dispatch) -> Nil {
  let UIRouterOptions(prevent_default:, ..) = options

  use event <- jsglobal.add_event_listener("onpopstate")

  let _ = jsevent.prevent_default(event)

  let href =
    location_href()
    |> result.unwrap(uri.empty)

  let _ = request_scroll(href, prevent_default)

  do_dispatch(dispatch, href)
}

/// Request animation to scroll default browser behavior
///
/// - href: Uri current
/// - prevent_default: If true, cancel not execute
///
fn request_scroll(href, prevent_default) {
  // disable default browser behavior
  use <- bool.guard(prevent_default, None)

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

  let hash = hash(href)

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
fn hash(href: uri.Uri) -> Option(String) {
  use hash <- option.then(href.fragment)
  let is_empty = string.length(hash) > 1

  case is_empty {
    True -> None
    False ->
      string.slice(hash, 0, 1)
      |> Some()
  }
}

/// Current window location href
///
fn location_href() {
  let href =
    jscore.global()
    |> jscore.get_object_inner_key("location", "href")

  parse_href(href)
}

/// Parse window location href string to uri.Uri
///
/// - href: String representation of uri
///
fn parse_href(href) {
  case href {
    Some(href) ->
      uri.parse(href)
      |> result.map_error(fn(_) { "Parse location.href to uri.Uri" })
      |> result.map_error(io.print_error)
    None -> Ok(uri.empty)
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

fn check_items(items: Items(t)) -> Result(Nil, RouterError) {
  case items {
    [] -> Error(UIRouterItemEmpty)
    [first, ..rest] -> unique_items(rest, first.id)
  }
}

fn unique_items(items: Items(t), id: String) {
  let has_id = any_id_items(items, id)

  // eager return
  use <- bool.guard(has_id, Error(UIRouterItemUnique))

  case items {
    [] -> Error(UIRouterItemEmpty)
    [first, ..rest] -> unique_items(rest, first.id)
  }
}

fn any_id_items(items: Items(t), id: String) {
  use item <- list.any(items)

  item.id == id
}
