{{flutter_js}}
{{flutter_build_config}}

const loading = document.createElement('div');
document.body.appendChild(loading);
loading.textContent = "Carregando...";

// _flutter.buildConfig = { "engineRevision": "edd8546116457bdf1c5bdfb13ecb9463d2bb5ed4", "builds": [{ "compileTarget": "dart2js", "renderer": "auto", "mainJsPath": "main.dart.js" }] };

var appDataJS = {
    'hostname': window.location.hostname,
    'href': window.location.href,
    'port': window.location.port,
  };

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    loading.textContent = "Initializing engine...";
    const appRunner = await engineInitializer.initializeEngine();

    loading.textContent = "Running app...";
    await appRunner.runApp();
  }
});