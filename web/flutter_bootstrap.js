{{flutter_js}}
{{flutter_build_config}}

var appDataJS = {
  'hostname': window.location.hostname,
  'href': window.location.href,
  'port': window.location.port,
};

const __progressUpdate = window.__appProgressUpdate || function () { };
const __progressLabel = window.__appProgressLabel || function () { };

__progressLabel('Carregando aplicação...');
__progressUpdate(10);

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    __progressLabel('Inicializando engine...');
    __progressUpdate(40);

    const appRunner = await engineInitializer.initializeEngine();

    __progressLabel('Iniciando interface...');
    __progressUpdate(70);

    await appRunner.runApp();

    __progressLabel('Pronto!');
    __progressUpdate(100);
  }
});
