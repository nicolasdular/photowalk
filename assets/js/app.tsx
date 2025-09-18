import "vite/modulepreload-polyfill";
import { render } from "preact";
import { HelloWorld } from "./components/HelloWorld";
import { listTodos } from "./ash_rpc";

const preactContainer = document.getElementById("preact-app");

if (preactContainer) {
  render(<HelloWorld />, preactContainer);
}
