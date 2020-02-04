import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class StatusBar extends Sprite {
 public static inline var Width = 84;
 public static inline var Height = 6;

 public static inline var WhiteColor = 0xc7f0d8;
 public static inline var BlackColor = 0x43523d;

 var tombSprite:BitmapData;

 public var tombStones:Int;

 public function new(tombStones) {
  super();
  this.tombStones = tombStones;
  this.tombSprite = Assets.getBitmapData("Assets/small_tomb.png");
  onFrame(1);
 }

 public function onFrame(timeLeft:Float) {
  this.graphics.beginFill(WhiteColor);
  this.graphics.drawRect(0, 0, Width, Height);

  if (this.tombStones > 0) {
   this.graphics.beginBitmapFill(this.tombSprite);
   this.graphics.drawRect(0, 0, Height * this.tombStones, Height);
  }

  this.graphics.beginFill(BlackColor);
  this.graphics.drawRect(Width / 2, Height / 2 - 1, (Width / 2 - 1) * timeLeft, 2);
 }
}
