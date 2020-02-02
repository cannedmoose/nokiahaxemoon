package;

import openfl.geom.Point;

class Grave {
  public enum GraveState {
    // Just been dug
    FRESH
  }
  private static Map<GraveState, BitmapData> STATE_SPRITES = null;

  public static function lazyInit() {
    if (SPRITE_SHEET != null) {
      return;
    }
    var spriteSheet = Assets.getBitmapData("graves.png", false);
    STATE_SPRITES = new Map();
    {
      var d = new BitmapData(16, 16, true);
      d.copyPixels(spriteSheet, new Rectangle(0, 0, 16, 16), new Point(0, 0));
      STATE_SPRITES[FRESH] = d;
    }
  }

  // The center of the initial hole.
  private final Point origin;

  public function new(origin:Point) {
    lazyInit();
    this.origin = origin;
  }
}
