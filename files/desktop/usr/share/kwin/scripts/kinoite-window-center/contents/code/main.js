function isCenterable(w) {
    return Boolean(
        w &&
        w.normalWindow &&
        !w.fullScreen &&
        !w.minimized &&
        !w.modal &&
        !w.transientFor &&
        w.moveable &&
        !w.skipTaskbar
    );
}

function centerWindow(w) {
    if (!isCenterable(w)) {
        return false;
    }
    if (w.width <= 0 || w.height <= 0) {
        return false;
    }
    var area = workspace.clientArea(KWin.PlacementArea, w);
    if (w.width >= area.width - 2 && w.height >= area.height - 2) {
        return true;
    }
    w.frameGeometry = {
        x: Math.round(area.x + (area.width - w.width) / 2),
        y: Math.round(area.y + (area.height - w.height) / 2),
        width: w.width,
        height: w.height
    };
    return true;
}

workspace.windowAdded.connect(function (w) {
    if (!isCenterable(w)) {
        return;
    }
    if (centerWindow(w)) {
        return;
    }
    function onGeometryChanged() {
        if (w.width > 0 && w.height > 0) {
            w.frameGeometryChanged.disconnect(onGeometryChanged);
            centerWindow(w);
        }
    }
    w.frameGeometryChanged.connect(onGeometryChanged);
});
