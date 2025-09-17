import "vite/modulepreload-polyfill";
import { render } from "preact";
import { HelloWorld } from "./components/HelloWorld";

const preactContainer = document.getElementById("preact-app");

if (preactContainer) {
  render(<HelloWorld />, preactContainer);
}
