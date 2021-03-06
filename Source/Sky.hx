package;

import openfl.geom.Vector3D;
import Shaders.NokiaShader;
import Shaders.CloudShader;
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

class Sky extends Sprite {
  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  public static inline var Width = 84;
  public static inline var Height = 48;

  public static inline var StarRows = 0;
  public static inline var StarCols = 0;

  var cloudNoise:BitmapData;

  var eprompt:EPrompt;

  public function new() {
    super();

    this.shader = new NokiaShader();

    this.graphics.beginFill(BlackColor);
    this.graphics.drawRect(0, 0, Width, Height);

    // Generate star field
    var star = new Sprite();
    for (i in 0...(StarRows * StarCols)) {
      star.graphics.beginFill(WhiteColor);
      var row = i / StarRows;
      var col = i % StarRows;
      var x = Math.round(col * Width / StarRows + Math.random() * Width / StarRows);
      var y = Math.round(row * Height / StarCols + Math.random() * Height / StarCols);
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
    this.cloudNoise = new BitmapData(84, 48, true, WhiteColor);
    cloudNoise.perlinNoise(0, -10, 2, 1, false, false, BitmapDataChannel.ALPHA, true);
    var cloud:Sprite = new Sprite();
    cloud.addChild(new Bitmap(cloudNoise));
    cloud.shader = new CloudShader();
    // Lower cutoff = smaller clouds
    cloud.shader.data.cutoff.value = [0.35];
    // How much the moonlight highlights clouds in x/y direction
    cloud.shader.data.lightMul.value = [1, 2];
    addChild(cloud);

    var titleData = Assets.getBitmapData("Assets/title.png");
    var title = new Bitmap(titleData);
    title.x = 27;
    title.y = 10;
    addChild(title);
  }

  public function onFrame(frame) {
    cloudNoise.perlinNoise(Math.floor(frame / 2), -10, 2, 1, false, false, BitmapDataChannel.ALPHA, true);
    if (frame > 15) {
      eprompt = new EPrompt();
      eprompt.x = 84 - 26;
      eprompt.y = 48 - 8;
      addChild(eprompt);
      eprompt.onFrame(1);
    }
  }
}
