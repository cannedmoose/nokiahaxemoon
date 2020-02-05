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

// Position == top left of "normal size"
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
  private var ghost:Ghost = null;

  public function new() {
    super();

    lazyInit();
    updateRenderSprite();
  }

  public function onDamage() {
    switch state {
      case NORMAL:
        setState(DAMAGED, ghost);
      case DAMAGED | SANCTIFIED:
        // nothing
    }
  }

  public function getState(): TombstoneState {
    return state;
  }

  public static function localSpacePathingCollider(): Rectangle {
    var tombstoneCollidingHeight = 1; // For walking behind tombstone
    // NOTE: always return new instance
    return new Rectangle(
        0, TOMBSTONE_HEIGHT - tombstoneCollidingHeight,
        TOMBSTONE_WIDTH + 1, tombstoneCollidingHeight + 1);
  }

  public function setState(state:TombstoneState, ghost:Ghost) {
    this.ghost = ghost;
    if (state == this.state) {
      return;
    }

    this.state = state;
    updateRenderSprite();
  }

  public function getLinkedGhost():Ghost {
    return ghost;
  }

  private function updateRenderSprite() {
    removeChildren();
    var g = new Bitmap(STATE_SPRITES[this.state]);
    g.x = 0;
    g.y = this.state == SANCTIFIED ? (TOMBSTONE_HEIGHT-SANCTIFIED_HEIGHT) : 0;
    addChild(g);
  }
}
