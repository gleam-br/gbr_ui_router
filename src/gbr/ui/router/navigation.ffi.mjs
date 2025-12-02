/**
 * @packageDocumentation
 * @module navigation
 *
 * _WIP_ Work in progress
 *
 * # FFI to navigation api javascript functions
 *
 * - https://github.com/WICG/navigation-api
 *
 * ## How to use new spec navigation-api to router my app?
 *
 * If browser supports `globalThis.navigation` api we should uses this.
 *
 */


export function main() {
  console.log(">>>>> HERE NAV")
}

function randomColor() {
  // ~~ bitwise NOT operator to truncate decimal and convert to integer 0..15
  return "#000000".replace(/0/g, function () { return (~~(Math.random() * 16)).toString(16); });
}

function setView(event) {
  return async () => {
    await new Promise(r => setTimeout(r, 2_000));
    try {

      let el = document.getElementById("app")

      el.style = "color: " + randomColor()
      el.innerHTML = `Navigated to ${event.destination.url}`;
      console.log(">>>>>> SET VIEW OK", el)
    } catch (e) {
      console.error(e)
    }
  }
}


function init() {
  if (!globalThis.navigation) {
    console.log(">>> NOT NAVIGATION")
    return
  }

  // Get the initial path that's being loaded
  let docUrl = new URL(document.URL);
  let url = new URL(document.URL).pathname;

  console.log(">>> ", document.URL)
  console.log(">>> ", docUrl)
  console.log(">>> ", window.location)
  console.log(">>> ", window.history)

  navigation.addEventListener('navigate', (event) => {
    // Get the path for the URL being navigated to
    url = new URL(event.destination.url).pathname;
    // If it's not covered by your SPA, return and it works as normal
    // For me, this means if it's not part of my admin path
    if (!url.startsWith('/admin')) return;

    if (event.canIntercept) {
      // If you do want deal with it, intercept the event and call a handler to change your view.
      // It can take an async function, important for dynamically loading your routes.
      // I'll get back to that in a second.
      event.intercept({ handler: setView(event) });
    }
  })
}

globalThis.myinit = init
