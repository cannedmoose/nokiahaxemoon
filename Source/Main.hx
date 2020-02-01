package;

import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.display.DisplayObjectShader;
import openfl.display.BlendMode;
import openfl.events.Event;
import openfl.Lib.getTimer;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.BitmapDataChannel;
import openfl.media.Sound;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

class Main extends Sprite {
	public static inline var WhiteColor = 0xc7f0d8;
	public static inline var BlackColor = 0x43523d;

	public static inline var Width = 84;
	public static inline var Height = 48;

	public static inline var StarRows = 10;
	public static inline var StarCols = 3;
	public function new() {
		super();

		// Enable nokie shader to restrict to monochrome.
		//this.cacheAsBitmap = true;
		this.shader = new NokiaShader();

		// Generate star field
		var star = new Sprite();
		for (i in 0...(StarRows*StarCols)) {
			star.graphics.beginFill(WhiteColor);
			var row = i/StarRows;
			var col = i%StarRows;
			var x = Math.round(col*Width/StarRows + Math.random()*Width/StarRows);
			var y = Math.round(row*Height/StarCols + Math.random()*Height/StarCols);
			star.graphics.drawRect(x, y, 1, 1);
		};
		addChild(star);

		// Crescent moon moon
		var moon = new Sprite();
		moon.graphics.beginFill(WhiteColor);
		moon.graphics.drawCircle(15, 15, 10);
		moon.graphics.beginFill(BlackColor);
		moon.graphics.drawCircle(10, 13, 9.5);
		addChild(moon);

		// Cloud sprite - a layer of perlin noise
		var cloudNoise:BitmapData = new BitmapData(84,48, true, WhiteColor);
		var noiseX = 20.0;
		cloudNoise.perlinNoise(Math.round(noiseX), 1, 2, 1, false, false, BitmapDataChannel.ALPHA , true);
		var cloud: Sprite = new Sprite();
		cloud.addChild(new Bitmap(cloudNoise));
		cloud.shader = new CloudShader();
		// Lower cutoff = smaller clouds
		cloud.shader.data.cutoff.value = [0.5];
		// How much the moonlight highlights clouds in x/y direction
		cloud.shader.data.lightMul.value = [2, 3];
		addChild(cloud);

		var speed = 1 / 1000;
		var cacheTime = getTimer();
		addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;

			noiseX += deltaTime*speed;
			cloudNoise.perlinNoise(Math.round(noiseX), 1, 2, 1, false, false, BitmapDataChannel.ALPHA , true);
			cacheTime = currentTime;
	
		});

    var music:Sound = Assets.getSound("Assets/k2lu.mp3");
    music.play(0, 999, new SoundTransform(0.6));
	}
}

/**
	Fragment shader for restricting colours to nokia legal ones.
**/
class NokiaShader extends DisplayObjectShader {
	@:glFragmentSource("
	#pragma header
	float luma(vec4 color) {
		return dot(color.rgb, vec3(0.299, 0.587, 0.114));
	}
	void main(void) {
		#pragma body
		 vec4 color2 = texture2D (openfl_Texture, openfl_TextureCoordv);
		 // If alpha is small, just remove alpha and let BG through.
		 if (color2.a < .45) {
			 gl_FragColor = vec4(0, 0 , 0 ,0);
		 } else if (luma(color2) < .3) {
			 gl_FragColor = vec4(0.263, 0.322, 0.239, 1.0) ;
		 } else {
			 gl_FragColor = vec4(0.78, 0.941, 0.847, 1.0);
		 }
	}
	")
	public function new() {
		super();
	}
}


/**
	Fragment shader for converting grayscale perlin noise to clouds.
**/
class CloudShader extends DisplayObjectShader {
	@:glFragmentSource("
	#pragma header
	uniform float cutoff;
	uniform vec2 lightMul;
	float luma(vec4 color) {
		return dot(color.rgb, vec3(0.299, 0.587, 0.114));
	}

	int neighbourEmpty(vec2 pos) {
		vec2 onePixel = lightMul / openfl_TextureSize;
		vec4 c = texture2D (openfl_Texture, openfl_TextureCoordv + (onePixel*pos));
		if (luma(c) > cutoff){return 1;}
		else {return 0;};
	}

	void main(void) {
		#pragma body
		 vec4 pixel = texture2D (openfl_Texture, openfl_TextureCoordv);
		 int emptyNeighbours = neighbourEmpty(vec2(-1, -1)) 
			 + neighbourEmpty(vec2(0, -1))
			 + neighbourEmpty(vec2(1, -1))
			 + neighbourEmpty(vec2(-1, 0))
			 + neighbourEmpty(vec2(-1, 1))
			 + neighbourEmpty(vec2(1, 0))
			 + neighbourEmpty(vec2(0, 1))
			 + neighbourEmpty(vec2(1, 1));
		
			if ( luma(pixel) < cutoff) {
			 if (emptyNeighbours > 2) {
				 gl_FragColor = vec4(0.78, 0.941, 0.847, 1);
			 } else {
				 gl_FragColor = vec4(0.263, 0.322, 0.239, 1);
			 }
		 } else {
			gl_FragColor = vec4(0, 0, 0, 0);
		 }
	}
	")
	public function new() {
		super();
	}
}
