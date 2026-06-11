{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      canvasKitBaseUrl: "canvaskit/",
      fontFallbackBaseUrl: "assets/fonts/"
    });
    await appRunner.runApp();
  }
});
