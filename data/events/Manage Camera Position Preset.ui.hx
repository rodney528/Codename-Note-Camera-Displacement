function generateIcon():Void {
	switch (event.name) {
		case 'Manage Camera Position Preset':
			if (event.params != null) {
				if (!inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					if (event.params[1]) generateEventIconDurationArrow(group, event.params[2]);
					generateEventIconNumbers(group, event.params[1], 4, -12);
					generateEventIconNumbers(group, event.params[2], 4, 21);
					return group;
				}
			}
	}
}