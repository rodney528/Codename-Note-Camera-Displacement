import haxe.ds.StringMap;
import funkin.backend.system.Flags;

// Main vars.
/**
 * X and Y displacement offset.
 * default: 30
 */
public var displacementOffset:FlxPoint = FlxPoint.get(30, 30);
/**
 * Do you want the camera to snap to the player cam position on miss?
 * default: true
 */
public var canSnapOnMiss:Bool = true;
/**
 * Remade the cool cam idle bop movement that Blantados did for his version!
 * default: true
 */
public var allowCamIdleBop:Bool = true;
/**
 * Change camera speed when hitting notes (reverts when none are being hit).
 * default: true, 1.5
 */
public var camVelocity = {
	active: true,
	mult: 1.5
}
/**
 * Who (per strumLine) has displacement?
 * default: blank (which defaults to true)
 */
public var activeDisplacementList:Array<Null<Bool>> = [];
/**
 * Allows all strumLine hits to cause camera displacement, no matter `curCameraTarget` value.
 * default: false
 */
public var allowAllPresses:Bool = false;
/**
 * Force which strumLine causes camera displacement. `null` to disable.
 * default: null
 */
public var forceTargetDetection:Null<Int> = null;

// Internal stuff.
public var presentCameraPositions:StringMap<FlxPoint> = new StringMap();
function snapCamPos():Void {
	camGame.targetOffset.set();
	camGame.snapToTarget();
	velocity = false;
}

var coolCamReturn:FlxTimer = new FlxTimer();
var camAfterBop:FlxTimer = new FlxTimer();
function cancelTimers() {
	coolCamReturn.cancel();
	camAfterBop.cancel();
}

var theCameraTarget(get, never):Int;
function get_theCameraTarget():Int
	return forceTargetDetection ?? curCameraTarget;

var velocity(default, set):Bool = false;
function set_velocity(value:Bool):Bool {
	if (velocity != value)
		camGame.followLerp = Flags.DEFAULT_CAMERA_FOLLOW_SPEED * (value && camVelocity.active ? camVelocity.mult : 1) / camGame.zoom;
	return velocity = value;
}

function onCameraMove(event):Void {
	var tweenIsActive:Bool = false;
	var tween:FlxTween = eventsTween.get('cameraMovement');
	if (tween != null) tweenIsActive = tween.active;

	if (!event.cancelled && !tweenIsActive) {
		if (cameraPositionOffset != null) {
			event.position.x = cameraPositionOffset[0];
			event.position.y = cameraPositionOffset[1];
		}
	}
}

var targetFixTimer:FlxTimer = new FlxTimer();
var cameraPositionOffset:Null<Array<Float>> = null;
function onEvent(event):Void {
	switch (event.event.name) {
		case 'Camera Movement':
			targetFixTimer.cancel();
			cameraPositionOffset = null;
			if (!event.event.params[1])
				snapCamPos();
			else {
				camGame.targetOffset.set();
				velocity = false;
			}
		case 'Camera Position':
			targetFixTimer.cancel();
			cameraPositionOffset = null;
			if (!event.event.params[2])
				snapCamPos();
			else {
				camGame.targetOffset.set();
				velocity = false;
				if (event.event.params[4] != null && event.event.params[4] != 'CLASSIC') {
					var last:Int = curCameraTarget;
					var ugh = event.event.params[6];
					targetFixTimer.start((Conductor.stepCrochet / 1000) * (event.event.params[3] == null ? 4 : event.event.params[3]), (_) -> curCameraTarget = last);
				} else {
					var last:Int = curCameraTarget;
					targetFixTimer.start(0.1, (_) -> curCameraTarget = last);
				}
			}
			var isOffset:Bool = event.event.params[6];
			if (isOffset)
				cameraPositionOffset = [isOffset ? (camFollow.x + event.event.params[0]) : event.event.params[0], isOffset ? (camFollow.y + event.event.params[1]) : event.event.params[1]];
			else cameraPositionOffset = null;
		case 'Camera Position Preset':
			if (!presentCameraPositions.exists(event.event.params[0])) return;
			var present:FlxPoint = presentCameraPositions.get(event.event.params[0]);

			var tween:FlxTween = eventsTween.get('cameraMovement');
			if (tween != null) {
				if (tween.onComplete != null) tween.onComplete(tween);
				tween.cancel();
			}

			camFollow.setPosition(present.x, present.y);
			if (event.event.params[1] == false) FlxG.camera.snapToTarget();
			else if (event.event.params[3] != null && event.event.params[3] != 'CLASSIC') {
				var oldFollow:Bool = FlxG.camera.followEnabled;
				FlxG.camera.followEnabled = false;
				eventsTween.set('cameraMovement', FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x - FlxG.camera.width * 0.5, y: camFollow.y - FlxG.camera.height * 0.5},
					(Conductor.stepCrochet / 1000) * (event.event.params[2] == null ? 4 : event.event.params[2]), {
						ease: CoolUtil.flxeaseFromString(event.event.params[3], event.event.params[4]),
						onComplete: (_) -> {
							FlxG.camera.followEnabled = oldFollow;
							cameraPositionOffset = [present.x, present.y];
						}
					})
				);
			} else cameraPositionOffset = [present.x, present.y];
		case 'Manage Camera Position Preset':
			var key:String = event.event.params[0];
			switch (event.event.params[3]) {
				case 'Save':
					presentCameraPositions.set(key, FlxPoint.get(event.event.params[1], event.event.params[2]));
				case 'Save (Current Position)':
					presentCameraPositions.set(key, FlxPoint.get(camFollow.x, camFollow.y));
				case 'Save (Offset Current Position)':
					presentCameraPositions.set(key, FlxPoint.get(camFollow.x + event.event.params[1], camFollow.y + event.event.params[2]));
				case 'Delete':
					if (presentCameraPositions.exists(key)) {
						var present:FlxPoint = presentCameraPositions.get(key);
						presentCameraPositions.remove(key);
						present.put();
					}
			}
			if (event.event.params[3] != 'Delete') {
				var present:FlxPoint = presentCameraPositions.get(key);
				trace(key + ': ' + present.x + ', ' + present.y);
			}
	}
}

function noteDataEKConverter(data:Int, amount:Int = 4):Int {
	if (amount == 1)
		if (data == 0) return 2;
		else return data;

	else if (amount == 2)
		if (data == 1) return 3;
		else return data;

	else if (amount == 3)
		if (data == 1) return 2;
		else if (data == 2) return 3;
		else return data;

	else if (amount == 4)
		return data;

	else if (amount == 5)
		if (data == 3) return 2;
		else if (data == 4) return 3;
		else return data;

	else if (amount == 6)
		if (data == 1) return 2;
		else if (data == 2) return 3;
		else if (data == 3) return 0;
		else if (data == 4) return 1;
		else if (data == 5) return 3;
		else return data;

	else if (amount == 7)
		if (data == 1) return 2;
		else if (data == 2) return 3;
		else if (data == 3) return 2;
		else if (data == 4) return 0;
		else if (data == 5) return 1;
		else if (data == 6) return 3;
		else return data;

	else if (amount == 8)
		if (data == 4) return 0;
		else if (data == 5) return 1;
		else if (data == 6) return 2;
		else if (data == 7) return 3;
		else return data;

	else if (amount == 9)
		if (data == 4) return 2;
		else if (data == 5) return 0;
		else if (data == 6) return 1;
		else if (data == 7) return 2;
		else if (data == 8) return 3;
		else return data;

	else return data % amount;
}

function onNoteHit(event):Void {
	var strumIndex:Int = strumLines.members.indexOf(event.note.strumLine);
	if (activeDisplacementList[strumIndex] ?? true && (allowAllPresses || strumIndex == theCameraTarget)) {
		var sustainLength:Float = event.note.nextNote?.sustainLength;
		velocity = true;
		switch (noteDataEKConverter(event.direction, event.note.strumLine.length)) {
			case 0: camGame.targetOffset.set(-displacementOffset.x, 0);
			case 1: camGame.targetOffset.set(0, displacementOffset.y);
			case 2: camGame.targetOffset.set(0, -displacementOffset.y);
			case 3: camGame.targetOffset.set(displacementOffset.x, 0);
			default: camGame.targetOffset.set();
		}
		camGame.targetOffset.set(camGame.targetOffset.x / camGame.zoom, camGame.targetOffset.y / camGame.zoom);
		cancelTimers();
		coolCamReturn.start((Conductor.stepCrochet / 1000) * (event.note.isSustainNote ? 0.6 : 1.6), (_) -> {
			camGame.targetOffset.set();
			velocity = false;
		});
	}
}

function onPlayerMiss(event):Void {
	var strumIndex:Int = strumLines.members.indexOf(event.note.strumLine);
	if (!event.cancelled && canSnapOnMiss && (allowAllPresses || strumIndex == theCameraTarget)) {
		cancelTimers();
		snapCamPos();
	}
}

function camIdleBop(onTick:Int):Void {
	if (theCameraTarget != -1 && allowCamIdleBop && !inCutscene) {
		camGame.targetOffset.set();
		var char:Character = strumLines.members[theCameraTarget].characters[0];
		if (char == null && char.lastAnimContext != 'DANCE') return;
		function addIdleSuffix(anim:String):String return anim + char.idleSuffix;
		if (char.hasAnimation(addIdleSuffix('danceLeft')) && char.hasAnimation(addIdleSuffix('danceRight'))) {
			if ((onTick + char.beatOffset) % char.beatInterval == 0) {
				if (char.getAnimName() == addIdleSuffix('danceLeft')) {
					cancelTimers();
					camGame.targetOffset.set();
					camGame.targetOffset.x -= displacementOffset.x / 2;
					camGame.targetOffset.y -= displacementOffset.y / 2;
					camAfterBop.start((Conductor.crochet / 1000) / 2, () -> camGame.targetOffset.set());
				} else if (char.getAnimName() == addIdleSuffix('danceRight')) {
					cancelTimers();
					camGame.targetOffset.set();
					camGame.targetOffset.x += displacementOffset.x / 2;
					camGame.targetOffset.y -= displacementOffset.y / 2;
					camAfterBop.start((Conductor.crochet / 1000) / 2, () -> camGame.targetOffset.set());
				}
			}
		} else {
			if (char.getAnimName() == addIdleSuffix('idle')) {
				if ((onTick + char.beatOffset) % char.beatInterval == 0) {
					cancelTimers();
					camGame.targetOffset.set();
					camGame.targetOffset.y += displacementOffset.y / 2;
					camAfterBop.start((Conductor.crochet / 1000) / 2, () -> camGame.targetOffset.set());
				}
			}
		}
	}
}

function onCountdown(event):Void camIdleBop(event.swagCounter);
function beatHit(curBeat:Int):Void camIdleBop(curBeat);

function destroy():Void {
	displacementOffset.put();
	for (point in presentCameraPositions)
		point.put();
}