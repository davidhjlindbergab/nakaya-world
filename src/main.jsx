import { createRoot } from "react-dom/client";
import "./index.css";
import NakayaWorld from "./nakaya-world.jsx";

// No StrictMode. Its dev-only double-invoke of effects would log every
// encounter and practice to Supabase twice, which makes the database
// impossible to read while wiring the backend up.
createRoot(document.getElementById("root")).render(<NakayaWorld />);
