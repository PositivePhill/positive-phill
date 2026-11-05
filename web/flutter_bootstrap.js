{{flutter_js}}
{{flutter_build_config}}
// GitHub Pages serves every file with max-age=600, so a fresh index.html can
// otherwise pair with a cached main.dart.js from the previous release. The
// per-build token makes the entrypoint URL unique; without it, refuse to start
// rather than load an unversioned entrypoint.
(function () {
  function fail(message) {
    window.dispatchEvent(new Event('pp-bootstrap-failed'));
    throw new Error('Positive Phill bootstrap: ' + message);
  }
  var build = {{flutter_service_worker_version}};
  if (typeof build !== 'string' || !/^[0-9]+$/.test(build)) {
    fail('missing build token');
  }
  var builds = _flutter.buildConfig.builds.filter(function (b) {
    return typeof b.mainJsPath === 'string' && b.mainJsPath.length > 0;
  });
  if (builds.length === 0) {
    fail('no JavaScript entrypoint in build config');
  }
  builds.forEach(function (b) {
    b.mainJsPath += (b.mainJsPath.indexOf('?') === -1 ? '?' : '&') + 'pp=' + build;
  });
  _flutter.buildConfig.builds = builds;
})();
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});
