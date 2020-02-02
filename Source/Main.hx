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

    var testDig1Grave = new Grave();
    testDig1Grave.x = 14;
    testDig1Grave.y = 30;
    testDig1Grave.setState(DIG_1);
    addChild(testDig1Grave);
    var testDig2Grave = new Grave();
    testDig2Grave.x = 22;
    testDig2Grave.y = 30;
    testDig2Grave.setState(DIG_2);
    addChild(testDig2Grave);
    var testFreshGrave = new Grave();
    testFreshGrave.x = 30;
    testFreshGrave.y = 30;
    addChild(testFreshGrave);
    var testFullGrave = new Grave();
    testFullGrave.x = 38;
    testFullGrave.y = 30;
    testFullGrave.setState(FULL);
    addChild(testFullGrave);

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 999, new SoundTransform(0.6));
	}
}
