/* eslint-disable */

const renamePlugin = (opts = {}) => {
  return {
    postcssPlugin: "postcss-rename-component-class",
    Root(root, postcss) {
      root.walkRules((atrule) => {
        if (atrule.source == undefined) {
          return;
        }
        const matches = atrule.source.input.file.match(
          /\/app\/components\/?(.*)\/component.css$/
        );

        const ruleType = (selector) => {
          if (selector[0] !== "." && selector[0] !== "#") {
            const selMatch = selector.match(/^(.+\s[\.|#])/);
            if (selMatch === null) {
              return selector;
            } else {
              return selector[0];
            }
          } else {
            return selector[0];
          }
        };

        const replaceClass = (replacement) => {
          if (atrule.type === "rule" && atrule.parent.type !== "atrule") {
            const selectors = atrule.selector
              .split(",")
              .map((sel) => sel.trim());

            let newSelectors = [];

            // If there's one selector, and the ruleType is a class or ID, then wrap it,
            // else prefix with the component name and dump it.
            if (selectors.length === 1 && ruleType(selectors[0]).length === 1) {
              newSelectors = selectors.map(
                (sel) =>
                  `${ruleType(sel)}${replacement}-${sel.replace(
                    ruleType(sel),
                    ""
                  )}`
              );
            } else {
              newSelectors = [`.${replacement} ${selectors}`];
            }

            const removeDupeSelector = (inputString) => {
              // Split the input string into words
              const words = inputString.split(/[- >]+/);

              // Find the duplicate consecutive words
              let duplicateWord = "";
              for (let i = 0; i < words.length - 1; i++) {
                if (words[i].trim() === words[i + 1].trim()) {
                  duplicateWord = words[i].trim();
                }
              }

              // If a duplicate word is found, remove it from the end of the string
              let result = inputString;
              if (duplicateWord !== "") {
                const pattern = new RegExp(
                  `${duplicateWord}-${duplicateWord}`,
                  "g"
                );
                result = inputString.replace(pattern, duplicateWord);
              }

              return result;
            };

            atrule.selector = newSelectors.map(removeDupeSelector).join(",");
          }

          // Handle Keyframes which for some reason are different
          if (
            atrule.type === "rule" &&
            atrule.parent.type === "atrule" &&
            atrule.parent.name === "keyframes" &&
            atrule.parent.class_renamed === undefined
          ) {
            atrule.parent.params = `${replacement}-${atrule.parent.params}`;
            atrule.parent.class_renamed = true;
          }
        };

        if (matches) {
          const identifier = matches[1].replace("/", "--").replace("_", "-");
          const newSelector = `c-${identifier}`;

          replaceClass(newSelector);
        }
      });
    },
  };
};

renamePlugin.postcss = true;

export default renamePlugin;
