{{flutter_js}}
{{flutter_build_config}}

// Opt in when a browser or graphics driver cannot compile WebGL shaders.
const softwareRendering =
  new URLSearchParams(window.location.search).get('rendering') === 'software';

_flutter.loader.load({
  config: softwareRendering
    ? { renderer: 'canvaskit', canvasKitForceCpuOnly: true }
    : {},
});
