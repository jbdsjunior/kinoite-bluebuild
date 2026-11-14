const TARGETS = new Set([
    "com.brave.browser",
    "com.google.chrome",
    "brave-browser",
    "google-chrome"
]);

function centerWindow(w) {
    if (!w || !w.normalWindow || w.fullScreen || !w.moveable) {
        return;
    }
    var cls = (w.resourceClass || "").toLowerCase();
    if (!TARGETS.has(cls)) {
        return;
    }
    var area = workspace.clientArea(KWin.PlacementArea, w);
    if (w.width >= area.width && w.height >= area.height) {
        return;
    }
    w.frameGeometry = {
        x: Math.round(area.x + (area.width - w.width) / 2),
        y: Math.round(area.y + (area.height - w.height) / 2),
        width: w.width,
        height: w.height
    };
}

workspace.windowAdded.connect(centerWindow);
