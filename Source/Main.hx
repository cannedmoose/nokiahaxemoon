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
		var dampe = new Dampe();
		addChild(dampe);
		dampe.init();
		dampe.x = 10;
		dampe.y = 10;

		var speed = 1 / 1000;
		var cacheTime = getTimer();
		addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			cacheTime = currentTime;
		});

    var testDig1Grave = createGraveAtPoint(new Point(14, 30));
    testDig1Grave.setState(DIG_1);
    addChild(testDig1Grave);
    var testDig2Grave = createGraveAtPoint(new Point(22, 30));
    testDig2Grave.setState(DIG_2);
    addChild(testDig2Grave);
    var testFreshGrave = createGraveAtPoint(new Point(30, 30));
    addChild(testFreshGrave);
    var testFullGrave = createGraveAtPoint(new Point(38, 30));
    testFullGrave.setState(FULL);
    addChild(testFullGrave);

    {
      var g = findGraveHoleIntersecting(new Point(31, 32));
      trace("intersecting grave");
      trace(g);
      trace(g == testFreshGrave);
      trace(g == testFullGrave);
    }

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 9999, new SoundTransform(0.6));
	}

  function createGraveAtPoint(point:Point): Grave {
    var grave = new Grave();
    grave.x = point.x;
    grave.y = point.y;
    return grave;
  }

  // Result may be null
  function findGraveHoleIntersecting(point:Point): Grave {
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
