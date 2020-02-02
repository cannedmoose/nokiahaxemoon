package;

import Shaders.NokiaShader;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.display.DisplayObjectShader;
import openfl.display.BlendMode;
import openfl.events.Event;
import openfl.Lib.getTimer;
import openfl.media.Sound;
import openfl.media.SoundTransform;
import openfl.geom.Point;
import openfl.utils.Assets;

class Main extends Sprite {
	public static inline var WhiteColor = 0xc7f0d8;
	public static inline var BlackColor = 0x43523d;

	public static inline var Width = 84;
	public static inline var Height = 48;

	public function new() {
		super();

		Grave.lazyInit();

		// Enable nokie shader to restrict to monochrome.
		// this.cacheAsBitmap = true;
		this.shader = new NokiaShader();
		var dampe:Dampe;
		dampe = new Dampe(function(point) {
			trace("digging at", point);
			var worldPos = new Point(dampe.x + point.x, dampe.y + point.y);
			var existingGrave = findGraveHoleIntersecting(worldPos);
			if (existingGrave != null) {
				switch existingGrave.getState() {
					case DIG_1:
						existingGrave.setState(DIG_2);
					case DIG_2:
						existingGrave.setState(FRESH);
					case FRESH:
					case FULL:
				}
			} else {
				createGraveAtPoint(worldPos);
			}
		});
		addChild(dampe);
		dampe.init();
		dampe.x = 10;
		dampe.y = 10;

		var cacheTime = getTimer();
		this.addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			if (deltaTime > 200) {
				dampe.onFrame();
				cacheTime = currentTime;
			}
		});

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 9999, new SoundTransform(0.6));
	}

	function createGraveAtPoint(point:Point) {
		var grave = new Grave();
		grave.x = point.x;
		grave.y = point.y;
		addChildAt(grave, 0);
	}

	// Result may be null
	function findGraveHoleIntersecting(point:Point):Grave {
		for (i in 0...numChildren) {
			var child = getChildAt(i);
			if (Type.getClass(child) == Grave) {
				var g:Grave = cast(child, Grave);
				if (g.intersectsHole(point)) {
					return g;
				}
			}
		}
		return null;
	}
}
