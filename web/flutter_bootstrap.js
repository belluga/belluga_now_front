{{flutter_js}}
{{flutter_build_config}}

var appDataJS = {
  'hostname': window.location.hostname,
  'href': window.location.href,
  'port': window.location.port,
};

const __progressUpdate = window.__appProgressUpdate || function () { };
const __progressLabel = window.__appProgressLabel || function () { };

const __bellugaBuildSha = typeof window.__WEB_BUILD_SHA__ === 'string'
  ? window.__WEB_BUILD_SHA__.trim()
  : '';

if (
  __bellugaBuildSha.length > 0
  && _flutter.buildConfig
  && Array.isArray(_flutter.buildConfig.builds)
) {
  for (const build of _flutter.buildConfig.builds) {
    if (!build || typeof build !== 'object') continue;
    const mainJsPath =
      typeof build.mainJsPath === 'string' && build.mainJsPath.length > 0
        ? build.mainJsPath
        : 'main.dart.js';
    const separator = mainJsPath.includes('?') ? '&' : '?';
    build.mainJsPath =
      `${mainJsPath}${separator}v=${encodeURIComponent(__bellugaBuildSha)}`;
  }
}

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
