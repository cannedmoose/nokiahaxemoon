package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

enum TombstoneState {
  NORMAL;
  DAMAGED;
  SANCTIFIED;
}

// Position == bottom left
class Tombstone extends Sprite {
  private static final TOMBSTONE_HEIGHT = 7;
  private static final TOMBSTONE_WIDTH = 7;
  private static final SANCTIFIED_HEIGHT = 9;

  private static var STATE_SPRITES:Map<TombstoneState, BitmapData> = null;

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
    STATE_SPRITES[NORMAL] = bitmapDataFromRect(spriteSheet, new Rectangle(24, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT));
    STATE_SPRITES[DAMAGED] = bitmapDataFromRect(spriteSheet, new Rectangle(40, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT));
    STATE_SPRITES[SANCTIFIED] = Assets.getBitmapData("Assets/cross2.png", false);
  }

  private var state:TombstoneState = TombstoneState.NORMAL;

  public function new() {
    super();

    lazyInit();
    updateRenderSprite();
  }

  public function getState(): TombstoneState {
    return state;
  }

  public static function localSpacePathingCollider(): Rectangle {
    var tombstoneCollidingHeight = 1; // For walking behind tombstone
    // NOTE: always return new instance
    return new Rectangle(
        0, tombstoneCollidingHeight,
        TOMBSTONE_WIDTH + 1, tombstoneCollidingHeight + 1);
  }

  public function setState(state:TombstoneState) {
    if (state == this.state) {
      return;
    }

    this.state = state;
    updateRenderSprite();
  }

  private function updateRenderSprite() {
    removeChildren();
    var g = new Bitmap(STATE_SPRITES[this.state]);
    g.x = 0;
    g.y = this.state == SANCTIFIED ? (-SANCTIFIED_HEIGHT) : (-TOMBSTONE_HEIGHT);
    addChild(g);
  }
}
