function generateIcon():Void {
	switch (event.name) {
		case 'Camera Position Preset':
			if (event.params != null) {
				if (!inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					if (event.params[1]) {
						generateEventIconDurationArrow(group, event.params[2]);
						group.members[0].y -= 2;
						generateEventIconNumbers(group, event.params[2]);
					}
					return group;
				} else return generateDefaultIcon(event.name);
			}
	}
}