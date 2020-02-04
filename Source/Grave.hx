package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

enum GraveState {
  // Digging in progress.
  DIG_1;
  DIG_2;

  // Just been dug
  HOLE;

  SPAWN_PROGRESS_1;
  SPAWN_PROGRESS_2;
}

// Position == "center of initial hole"
class Grave extends Sprite {
  private static final GRAVE_HEIGHT = 7;
  private static final GRAVE_WIDTH = 7;

  private static var STATE_SPRITES:Map<GraveState, BitmapData> = null;

  private static function bitmapDataFromRect(source:BitmapData, rect:Rectangle): BitmapData {
    var t = new BitmapData(cast (rect.width, Int), cast(rect.height, Int), true);
    t.copyPixels(source, rect, new Point(0, 0));
    return t;
  }

  public static function lazyInit() {
    if (STATE_SPRITES != null) {
      return;
    }
    var spriteSheet = Assets.getBitmapData("Assets/graves.png", false);
    STATE_SPRITES = new Map();

    STATE_SPRITES[DIG_1] = bitmapDataFromRect(spriteSheet, new Rectangle(47, 7, GRAVE_WIDTH, GRAVE_HEIGHT));
    STATE_SPRITES[DIG_2] = bitmapDataFromRect(spriteSheet, new Rectangle(40, 7, GRAVE_WIDTH, GRAVE_HEIGHT));
    STATE_SPRITES[HOLE] = bitmapDataFromRect(spriteSheet, new Rectangle(32, 7, GRAVE_WIDTH, GRAVE_HEIGHT));
    STATE_SPRITES[SPAWN_PROGRESS_1] = bitmapDataFromRect(spriteSheet, new Rectangle(24, 7, GRAVE_WIDTH, GRAVE_HEIGHT));
    STATE_SPRITES[SPAWN_PROGRESS_2] = bitmapDataFromRect(spriteSheet, new Rectangle(24, 14, GRAVE_WIDTH, GRAVE_HEIGHT));
  }

  private var state:GraveState = GraveState.DIG_1;

  public function new() {
    super();
    lazyInit();
    updateRenderSprite();
  }

  public function getState(): GraveState {
    return state;
  }

  public static function localSpaceGraveHoleRect(): Rectangle {
    return new Rectangle(
        - GRAVE_WIDTH / 2 - 1, - GRAVE_HEIGHT / 2 - 1,
        GRAVE_WIDTH + 1, GRAVE_HEIGHT + 1);
  }

  // May be null
  public function localSpacePathingCollisionRect(): Rectangle {
    switch state {
      case DIG_2 | HOLE:
        return localSpaceGraveHoleRect();
      case DIG_1 | SPAWN_PROGRESS_1 | SPAWN_PROGRESS_2:
        return null;
    }
  }

  public function setState(state:GraveState) {
    if (state == this.state) {
      return;
    }

    this.state = state;
    updateRenderSprite();
  }

  private function updateRenderSprite() {
    removeChildren();
    var g = new Bitmap(STATE_SPRITES[this.state]);
    g.x = - GRAVE_WIDTH / 2 - 1;
    g.y = - GRAVE_HEIGHT / 2 - 1;
    addChild(g);
  }
}
