module.exports = {
  plugins: ["stylelint-declaration-strict-value"],
  extends: ["stylelint-config-standard", "stylelint-prettier/recommended"],
  rules: {
    "at-rule-no-unknown": [
      true,
      {
        ignoreAtRules: [
          "tailwind",
          "apply",
          "variants",
          "responsive",
          "screen",
          "import-glob",
        ],
      },
    ],
    "color-hex-length": null,
    "declaration-empty-line-before": null,
    "declaration-no-important": true,
    "import-notation": null,
    "max-nesting-depth": 3,
    "no-empty-source": null,
    "selector-class-pattern": null,
    "no-invalid-position-at-import-rule": null,
    "property-no-unknown": [
      true,
      {
        // Allow property used for css-fonts-4 variable fonts
        ignoreProperties: ["font-named-instance"],
      },
    ],
    "scale-unlimited/declaration-strict-value": [
      "/color/",
      {
        disableFix: true,
        ignoreValues: [
          "currentcolor",
          "inherit",
          "initial",
          "transparent",
          "unset",
        ],
      },
    ],
    "selector-max-compound-selectors": 3,
    "selector-max-id": 0,
    "selector-no-qualifying-type": true,
    "shorthand-property-no-redundant-values": null,
  },
};
