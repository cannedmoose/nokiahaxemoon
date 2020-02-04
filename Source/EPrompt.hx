import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class EPrompt extends Sprite {
  public static inline var Width = 25;
  public static inline var Height = 7;

  var spriteSheet:BitmapData;
  var sprite:Bitmap;

  public function new() {
    super();
    this.spriteSheet = Assets.getBitmapData("Assets/press_e.png");
    this.sprite = new Bitmap(new BitmapData(Width, Height, true, 0xFFFFFFFF));
    addChild(this.sprite);
    this.onFrame(0);
  }

  public function onFrame(frame:Int) {
    var index = frame % 2;
    this.sprite.bitmapData.copyPixels(this.spriteSheet, new Rectangle(0, index * Height, Width, Height), new Point(0, 0));
  }
}
