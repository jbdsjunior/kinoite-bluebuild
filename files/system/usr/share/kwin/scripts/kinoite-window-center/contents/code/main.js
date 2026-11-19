function centerWindow(w) {
    if (!w || !w.normalWindow || w.fullScreen || w.minimized || w.modal || w.transientFor || !w.moveable || w.skipTaskbar) {
        return;
    }
    var area = workspace.clientArea(KWin.PlacementArea, w);
    if (w.width >= area.width - 2 && w.height >= area.height - 2) {
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
