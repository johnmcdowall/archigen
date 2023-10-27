import tailwindForms from "@tailwindcss/forms";
import tailwindTypography from "@tailwindcss/typography";
import tailwindAspectRatio from "@tailwindcss/aspect-ratio";

import multiThemePlugin from "./app/frontend/libs/tailwind_multi_theme_plugin.js";
import themes from "./themes.json";

export default {
  content: [
    "app/content/**/*",
    "app/views/**/*",
    "app/components/**/*",
    "app/helpers/**/*",
    "app/frontend/**/*",
  ],
  theme: {},
  plugins: [
    tailwindForms,
    tailwindTypography,
    tailwindAspectRatio,
    multiThemePlugin(themes),
  ],
};
