import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class Transition extends Sprite {
  public static inline var Width = 84;
  public static inline var Height = 48;
  public static inline var Length = 12;

  public var color:Int;

  public function new(color) {
    super();
    this.color = color;
    this.graphics.beginFill(0, 0);
    this.graphics.drawRect(0, 0, Width, Height);
  }

  public function onFrame(frame:Int) {
    if (frame == 0) {
      this.graphics.clear();
    }
    if (frame < Length / 2) {
      // Color in
      this.graphics.beginFill(color, 1);
    } else {
      // Color Out
      this.graphics.beginFill(0, 0);
      frame = frame - Math.floor(Length / 2);
    }

    if (frame < 3) {
      for (y in 0...(Height)) {
        for (x in 0...(Width)) {
          if (x % 2 == 0 && y % 2 == 0) {
            this.graphics.drawRect(x, y, 1, 1);
          }
        }
      }
    } else {
      for (y in 0...(Height)) {
        for (x in 0...(Width)) {
          if (x % 2 == 1 && y % 2 == 1) {
            this.graphics.drawRect(x, y, 1, 1);
          }
        }
      }
    }
  }
}
