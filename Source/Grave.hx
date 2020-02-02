package;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

// TODO maybe separate grave and tombstone state?
enum GraveState {
  // Just been dug
  FRESH;

  FULL;
  // TODO all states.
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

  public static function lazyInit() {
    if (STATE_SPRITES != null) {
      return;
    }
    var spriteSheet = Assets.getBitmapData("Assets/graves.png", false);
    STATE_SPRITES = new Map();

    // TODO load all sprites
    {
      var t = new BitmapData(TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT, true);
      t.copyPixels(spriteSheet, new Rectangle(0, 0, TOMBSTONE_WIDTH, TOMBSTONE_HEIGHT), new Point(0, 0));
      var g = new BitmapData(GRAVE_WIDTH, GRAVE_HEIGHT, true);
      g.copyPixels(spriteSheet, new Rectangle(0, 7, GRAVE_WIDTH, GRAVE_HEIGHT), new Point(0, 0));
      STATE_SPRITES[FULL] = new GraveStateBitmapData(t, g);
    }
    {
      var d = new BitmapData(GRAVE_WIDTH, GRAVE_HEIGHT, true);
      d.copyPixels(spriteSheet, new Rectangle(32, 7, GRAVE_WIDTH, GRAVE_HEIGHT), new Point(0, 0));
      STATE_SPRITES[FRESH] = new GraveStateBitmapData(null, d);
    }
  }

  private var state:GraveState = GraveState.FRESH;

  public function new() {
    super();

    lazyInit();
    updateRenderSprite();
  }

  public function setState(state:GraveState) {
    this.state = state;
    updateRenderSprite();
  }

  private function updateRenderSprite() {
    removeChildren();
    var data = STATE_SPRITES[this.state];
    if (data.tombstone != null) {
      var g = new Bitmap(data.tombstone.clone());
      g.x = - TOMBSTONE_WIDTH / 2 - 1;
      g.y = - GRAVE_HEIGHT - TOMBSTONE_HEIGHT / 2 - 1;
      addChild(g);
    }
    if (data.grave != null) {
      var g = new Bitmap(data.grave.clone());
      g.x = - GRAVE_WIDTH / 2 - 1;
      g.y = - GRAVE_HEIGHT / 2 - 1;
      addChild(g);
    }
  }
}
