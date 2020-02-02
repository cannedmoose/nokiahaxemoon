package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

enum GraveState {
  // Just been dug
  FRESH;

  // TODO all states.
}

// Position == "center of initial hole"
class Grave extends Sprite {
  private static var STATE_SPRITES:Map<GraveState, BitmapData> = null;

  public static function lazyInit() {
    if (STATE_SPRITES != null) {
      return;
    }
    var spriteSheet = Assets.getBitmapData("Assets/graves.png", false);
    STATE_SPRITES = new Map();

    // TODO load all sprites
    {
      var d = new BitmapData(7, 7, true);
      d.copyPixels(spriteSheet, new Rectangle(0, 0, 7, 7), new Point(0, 0));
      STATE_SPRITES[FRESH] = d;
    }
  }

  private var state:GraveState = GraveState.FRESH;

  public function new() {
    super();

    lazyInit();
    updateRenderSprite();
  }

  private function updateRenderSprite() {
    removeChildren();
    addChild(new Bitmap(STATE_SPRITES[this.state]));
  }
}
