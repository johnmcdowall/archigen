let CONTROLLER_FILENAME_REGEX =
  /^(?:.*?(?:controllers|components|stimulus)\/|\.?\.\/)?(.+)(?:[/_-]component\..+?)$/;

function registerControllers(application, controllerModules) {
  application.load(definitionsFromGlob(controllerModules));
}

function definitionsFromGlob(controllerModules) {
  return Object.entries(controllerModules)
    .map(definitionFromEntry)
    .filter((value) => value);
}

function definitionFromEntry([name, controllerModule]) {
  const identifier = identifierForGlobKey(name);
  const controllerConstructor = controllerModule.default;
  if (identifier && typeof controllerConstructor === "function")
    return { identifier, controllerConstructor };
}

function identifierForGlobKey(key) {
  let logicalName = (key.match(CONTROLLER_FILENAME_REGEX) || [])[1];
  if (logicalName) {
    logicalName = logicalName
      .replace(/_/g, "-")
      .replace(/\//g, "--")
      .replace(/--component/g, "");
    console.log(`Registering Stimulus controller ${logicalName}`);
    return logicalName;
  }
}

export {
  CONTROLLER_FILENAME_REGEX,
  definitionsFromGlob,
  identifierForGlobKey,
  registerControllers,
};
