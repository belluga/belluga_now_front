{{flutter_js}}
{{flutter_build_config}}

var appDataJS = {
  'hostname': window.location.hostname,
  'href': window.location.href,
  'port': window.location.port,
};

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
