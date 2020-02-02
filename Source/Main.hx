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

    var testGrave = new Grave();
    testGrave.x = 30;
    testGrave.y = 30;
    addChild(testGrave);

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 999, new SoundTransform(0.6));
	}
}
