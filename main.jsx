import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import NakayaWorld from "./nakaya-world.jsx";
import "./index.css";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <NakayaWorld />
  </StrictMode>,
);
