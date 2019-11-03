// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
import "phoenix_html"
import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

// Import local files
import hooks from "./hooks"

// Connect to LiveView socket
const params = {hello: "there!"};
const liveSocket = new LiveSocket("/live", Socket, {params, hooks});
liveSocket.connect();

// Extra stuff
window.copyToClipboard = (str) => {
  const el = document.createElement("textarea");  // Create a <textarea> element
  el.value = str;                                 // Set its value to the string that you want copied
  el.setAttribute("readonly", "");                // Make it readonly to be tamper-proof
  el.style.position = "absolute";                 
  el.style.left = "-9999px";                      // Move outside the screen to make it invisible
  document.body.appendChild(el);                  // Append the <textarea> element to the HTML document
  const selected =            
    document.getSelection().rangeCount > 0        // Check if there is any content selected previously
      ? document.getSelection().getRangeAt(0)     // Store selection if found
      : false;                                    // Mark as false to know no selection existed before
  el.select();                                    // Select the <textarea> content
  document.execCommand("copy");                   // Copy - only works as a result of a user action (e.g. click events)
  document.body.removeChild(el);                  // Remove the <textarea> element
  if (selected) {                                 // If a selection existed before copying
    document.getSelection().removeAllRanges();    // Unselect everything on the HTML document
    document.getSelection().addRange(selected);   // Restore the original selection
  }
};
