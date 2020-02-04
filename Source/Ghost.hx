package;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class Ghost extends Sprite {
  private static final WIDTH = 7;
  private static final HEIGHT = 7;
  private static final FRAMES_PER_ANIM = 4;
  private static final FRAMES_PER_MOVE = FRAMES_PER_ANIM * 2;

  private static var TEXTURE_1:BitmapData = null;
  private static var TEXTURE_2:BitmapData = null;

  private var frameCounter = 0;
  private var flipHorz = false;

  public static function localSpaceCollider():Rectangle {
    return new Rectangle(0, 0, WIDTH + 1, HEIGHT + 1);
  }

  public static function initTextures() {
    if (TEXTURE_1 != null) {
      return;
    }
    var spriteSheet = Assets.getBitmapData("Assets/ghost.png", false);
    TEXTURE_1 = new BitmapData(WIDTH, HEIGHT, true);
    TEXTURE_1.copyPixels(spriteSheet, new Rectangle(0, 0, WIDTH, HEIGHT), new Point(0, 0));
    TEXTURE_2 = new BitmapData(WIDTH, HEIGHT, true);
    TEXTURE_2.copyPixels(spriteSheet, new Rectangle(0, HEIGHT, WIDTH, HEIGHT), new Point(0, 0));
  }

  public function new() {
    super();
    initTextures();
    updateSprite();
  }

  public function onFrame() {
    frameCounter++;
    if (frameCounter % FRAMES_PER_MOVE == 0) {
      final xDir = Std.random(3) - 1;
      if (xDir < 0) {
        flipHorz = true;
      } else if (xDir > 0) {
        flipHorz = false;
      }
      this.x += xDir;
      this.y += Std.random(3) - 1;
    }
    updateSprite();
  }

  private function updateSprite() {
    if (frameCounter % FRAMES_PER_ANIM == 0) {
      removeChildren();
      var b = new Bitmap((frameCounter % (2 * FRAMES_PER_ANIM) == 0) ? TEXTURE_1 : TEXTURE_2);
      b.scaleX = flipHorz ? -1 : 1;
      b.x = flipHorz ? WIDTH : 0;
      addChild(b);
    }
  }
}
