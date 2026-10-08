{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  // Nothing loads from a third party: by default Flutter fetches the renderer
  // from www.gstatic.com and Roboto (loaded on every start) plus any missing
  // glyph from fonts.gstatic.com, handing every visitor's IP to Google. The
  // renderer ships in build/web/canvaskit, Roboto in web/fonts/fallback.
  // ponytail: other fallback fonts are not self-hosted, so a glyph outside
  // Inter / JetBrains Mono / Roboto (emoji, CJK in a plan name) draws as a
  // box; add its file under fonts/fallback/ if that ever matters.
  // See docs/privacy-audit.md.
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "fonts/fallback/",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
