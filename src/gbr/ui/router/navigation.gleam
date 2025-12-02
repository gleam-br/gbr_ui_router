////
////
////

import gleam/int
import gleam/option.{None, Some}
import gleam/string

import gbr/js/jscore

pub fn main() -> Nil {
  echo ">>>>> HERE NAV GLEAM"
  echo color_random()

  Nil
}

fn setup() {
  let validation =
    jscore.global()
    |> jscore.get_object_key("navigation")

  case validation {
    Some(validation) -> echo validation
    None -> echo "NONE"
  }
  // if (!globalThis.navigation) {
  //   console.log(">>> NOT NAVIGATION")
  //   return
  // }

  // // Get the initial path that's being loaded
  // let docUrl = new URL(document.URL);
  // let url = new URL(document.URL).pathname;

  // console.log(">>> ", document.URL)
  // console.log(">>> ", docUrl)
  // console.log(">>> ", window.location)
  // console.log(">>> ", window.history)

  // navigation.addEventListener('navigate', (event) => {
  //   // Get the path for the URL being navigated to
  //   url = new URL(event.destination.url).pathname;
  //   // If it's not covered by your SPA, return and it works as normal
  //   // For me, this means if it's not part of my admin path
  //   if (!url.startsWith('/admin')) return;

  //   if (event.canIntercept) {
  //     // If you do want deal with it, intercept the event and call a handler to change your view.
  //     // It can take an async function, important for dynamically loading your routes.
  //     // I'll get back to that in a second.
  //     event.intercept({ handler: setView(event) });
  //   }
  // })
}

fn color_random() {
  "#" <> color("")
}

fn color(acc) -> String {
  case string.length(acc) < 6 {
    False -> acc
    True ->
      {
        acc
        <> int.random(16)
        |> int.to_base16()
      }
      |> color()
  }
}
