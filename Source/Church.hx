package;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class Church extends Sprite {
  private static final WIDTH = 11;
  private static final HEIGHT = 12;


  public function new() {
    super();
    addChild(new Bitmap(Assets.getBitmapData("Assets/building2.png", false)));
  }

  public static function localCollider(): Rectangle {
    return new Rectangle(0, 0, WIDTH, HEIGHT);
  }
}

