import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class GameEnd extends Sprite {
  public static inline var Width = 84;
  public static inline var Height = 48;

  var winSpriteData:BitmapData;
  var loseSpriteData:BitmapData;

  var displayBitmap:Bitmap;

  public var won:Bool;

  public function new(won) {
    super();
    this.won = won;
    this.winSpriteData = Assets.getBitmapData("Assets/sunset.png");
    this.loseSpriteData = Assets.getBitmapData("Assets/overdue.png");

    this.displayBitmap = new Bitmap(new BitmapData(Width, Height, true));
    addChild(displayBitmap);
  }

  public function onFrame(frame:Int) {
    trace(won);
    if (won) {
      this.displayBitmap.bitmapData.copyPixels(winSpriteData, new Rectangle(0, Height * (Math.floor(frame / 4) % 2), Width, Height), new Point(0, 0));
    } else {
      this.displayBitmap.bitmapData.copyPixels(loseSpriteData, new Rectangle(0, 0, Width, Height), new Point(0, 0));
    }
  }
}
