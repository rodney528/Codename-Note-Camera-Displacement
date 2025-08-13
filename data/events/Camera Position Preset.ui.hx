function generateIcon():Void {
	switch (event.name) {
		case 'Camera Position Preset':
			if (event.params != null) {
				if (!inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					if (event.params[1] && event.params[3] != 'CLASSIC')
						generateEventIconDurationArrow(group, event.params[2]);
					return group;
				}
			}
	}
}