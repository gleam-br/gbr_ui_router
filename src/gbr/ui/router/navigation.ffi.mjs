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

async function setView(event) {
  await new Promise(r => setTimeout(r, 10_000));
  let el = document.getElementById("app")

  el.innerHTML = `Navigated to ${event.destination.url}`;
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

  navigation.addEventListener('navigate', (event) => {
    // Get the path for the URL being navigated to
    url = new URL(e.destination.url).pathname;
    // If it's not covered by your SPA, return and it works as normal
    // For me, this means if it's not part of my admin path
    if (!url.startsWith('/admin')) return;

    // If you do want deal with it, intercept the event and call a handler to change your view.
    // It can take an async function, important for dynamically loading your routes.
    // I'll get back to that in a second.
    e.intercept({ handler: setView(event) });
  })
}

globalThis.myinit = init
