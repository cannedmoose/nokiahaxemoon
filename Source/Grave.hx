package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

// TODO maybe separate grave and tombstone state?
enum GraveState {
  // Digging in progress.
  DIG_1;
  DIG_2;

  // Just been dug
  FRESH;

  FULL;
  FULL_STEPPED_ON_1;
  FULL_STEPPED_ON_2;
  FULL_STEPPED_ON_3;

  DEFILED;
}

class GraveStateBitmapData {
  // May be null.
  public final tombstone:BitmapData;
  public final grave:BitmapData;

  public function new( tombstone:BitmapData,grave:BitmapData) {
    this.tombstone = tombstone;
    this.grave = grave;
  }
}

// Position == "center of initial hole"
class Grave extends Sprite {
  private static final TOMBSTONE_HEIGHT = 7;
  private static final TOMBSTONE_WIDTH = 7;
  private static final GRAVE_HEIGHT = 7;
  private static final GRAVE_WIDTH = 7;

  private static var STATE_SPRITES:Map<GraveState, GraveStateBitmapData> = null;

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

    // TODO load all sprites
    STATE_SPRITES[DIG_1] = new GraveStateBitmapData(
        null,
        bitmapDataFromRect(spriteSheet, new Rectangle(47, 7, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[DIG_2] = new GraveStateBitmapData(
        null,
        bitmapDataFromRect(spriteSheet, new Rectangle(40, 7, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[FRESH] = new GraveStateBitmapData(
        null,
        bitmapDataFromRect(spriteSheet, new Rectangle(32, 7, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[FULL] = new GraveStateBitmapData(
        bitmapDataFromRect(spriteSheet, new Rectangle(0, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT)),
        bitmapDataFromRect(spriteSheet, new Rectangle(24, 14, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[FULL_STEPPED_ON_1] = new GraveStateBitmapData(
        bitmapDataFromRect(spriteSheet, new Rectangle(0, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT)),
        bitmapDataFromRect(spriteSheet, new Rectangle(16, 14, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[FULL_STEPPED_ON_2] = new GraveStateBitmapData(
        bitmapDataFromRect(spriteSheet, new Rectangle(0, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT)),
        bitmapDataFromRect(spriteSheet, new Rectangle(8, 14, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[FULL_STEPPED_ON_3] = new GraveStateBitmapData(
        bitmapDataFromRect(spriteSheet, new Rectangle(32, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT)),
        bitmapDataFromRect(spriteSheet, new Rectangle(0, 14, GRAVE_WIDTH, GRAVE_HEIGHT)));
    STATE_SPRITES[DEFILED] = new GraveStateBitmapData(
        bitmapDataFromRect(spriteSheet, new Rectangle(40, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT)),
        bitmapDataFromRect(spriteSheet, new Rectangle(55, 7, GRAVE_WIDTH, GRAVE_HEIGHT)));
  }

  private var state:GraveState = GraveState.DIG_1;
  private var holeIntersectionSprite: DisplayObject = null;
  private var graveCurrentlyBeingStoodOn = false;
  private var defilementListener:Grave->Void;

  public function new(defilementListener:Grave->Void) {
    super();

    this.defilementListener = defilementListener;

    lazyInit();
    updateRenderSprite();
  }

  public function getState(): GraveState {
    return state;
  }

  public function setGraveCurrentlyBeingStoodOn(b:Bool) {
    if (b == graveCurrentlyBeingStoodOn) {
      return;
    }
    if (b) {
      switch state {
        case FULL:
          setState(FULL_STEPPED_ON_1);
        case FULL_STEPPED_ON_1:
          setState(FULL_STEPPED_ON_2);
        case FULL_STEPPED_ON_2:
          setState(FULL_STEPPED_ON_3);
        case FULL_STEPPED_ON_3:
          setState(DEFILED);
        case DIG_1 | DIG_2 | DEFILED | FRESH:
      }
    }
    graveCurrentlyBeingStoodOn = b;
  }

  public static function localSpaceTombstonePathingCollisionRect(): Rectangle {
    var tombstoneNonCollidingHeight = 6; // For walking behind tombstone
    return new Rectangle(
        - TOMBSTONE_WIDTH / 2 - 1, - GRAVE_HEIGHT  - TOMBSTONE_HEIGHT / 2 - 1 + tombstoneNonCollidingHeight,
        TOMBSTONE_WIDTH + 1, TOMBSTONE_HEIGHT + 1 - tombstoneNonCollidingHeight);
  }

  public static function localSpaceGraveHoleRect(): Rectangle {
    return new Rectangle(
        - GRAVE_WIDTH / 2 - 1, - GRAVE_HEIGHT / 2 - 1,
        GRAVE_WIDTH + 1, GRAVE_HEIGHT + 1);
  }

  public function localSpacePathingCollisionRect(): Rectangle {
    switch state {
      case DIG_1 | DIG_2 | FRESH:
        return localSpaceGraveHoleRect();
      case FULL | FULL_STEPPED_ON_1 | FULL_STEPPED_ON_2 | FULL_STEPPED_ON_3:
        return localSpaceTombstonePathingCollisionRect();
      case DEFILED:
        return localSpaceTombstonePathingCollisionRect().union(localSpaceGraveHoleRect());
    }
  }

  public function setState(state:GraveState) {
    if (state == this.state) {
      return;
    }

    this.state = state;
    updateRenderSprite();
    if (state == DEFILED) {
      defilementListener(this);
    }
  }

  public function intersectsHole(point:Point): Bool {
    return holeIntersectionSprite == null ? false : holeIntersectionSprite.hitTestPoint(point.x, point.y);
  }

  private function updateRenderSprite() {
    removeChildren();
    var data = STATE_SPRITES[this.state];
    if (data.tombstone != null) {
      var g = new Bitmap(data.tombstone);
      g.x = - TOMBSTONE_WIDTH / 2 - 1;
      g.y = - GRAVE_HEIGHT - TOMBSTONE_HEIGHT / 2 - 1;
      addChild(g);
    }
    if (data.grave != null) {
      var g = new Bitmap(data.grave);
      g.x = - GRAVE_WIDTH / 2 - 1;
      g.y = - GRAVE_HEIGHT / 2 - 1;
      holeIntersectionSprite = g;
      addChild(g);
    } else {
      holeIntersectionSprite = null;
    }
  }
}
