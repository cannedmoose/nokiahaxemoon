import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

private enum DampeState {
  Walking(frame:Int, still:Bool);
  ShovelDown(frame:Int);
  Sitting(frame:Int, still:Bool);
}

class GameEnd extends Sprite {
  public static inline var Width = 84;
  public static inline var Height = 48;

  public static inline var DampeWidth = 11;
  public static inline var DampeHeight = 13;

  var winSpriteData:BitmapData;
  var loseSpriteData:BitmapData;
  var dampeSprite:BitmapData;

  var displayBitmap:Bitmap;
  var dampe:Bitmap;
  var state:DampeState;
  var audioManager:AudioManager;

  public var won:Bool;

  public function new(won, audioManager:AudioManager) {
    super();
    this.won = won;
    this.audioManager = audioManager;
    this.dampeSprite = Assets.getBitmapData("Assets/sunset_dampe.png");
    this.winSpriteData = Assets.getBitmapData("Assets/sunset.png");
    this.loseSpriteData = Assets.getBitmapData("Assets/overdue.png");

    this.state = Walking(0, true);

    this.displayBitmap = new Bitmap(new BitmapData(Width, Height, true));
    addChild(displayBitmap);

    this.dampe = new Bitmap(new BitmapData(DampeWidth, DampeHeight, true));
    addChild(dampe);
  }

  public function onFrame(frame:Int) {
    if (frame == 0) {
      if (won) {
        this.state = Walking(-1, false);
        this.dampe.x = Width;
        this.dampe.y = Height - DampeHeight - 1;
        audioManager.playVictory();
      } else {
        this.state = Walking(-1, true);
        this.dampe.x = 61;
        this.dampe.y = Height - DampeHeight - 1;
        audioManager.playDefeat();
      }
    }
    if (won) {
      this.displayBitmap.bitmapData.copyPixels(winSpriteData, new Rectangle(0, Height * (Math.floor(frame / 4) % 2), Width, Height), new Point(0, 0));
    } else {
      this.displayBitmap.bitmapData.copyPixels(loseSpriteData, new Rectangle(0, 0, Width, Height), new Point(0, 0));
    }
    if (frame % 3 == 1) {
      return;
    }
    switch (this.state) {
      case Walking(frame, true):
        if (frame > 5) {
          state = ShovelDown(0);
        } else {
          state = Walking(frame + 1, true);
        }
      case Walking(frame, false):
        if (frame > 30) {
          state = ShovelDown(0);
        } else {
          this.dampe.x -= 1;
          state = Walking(frame + 1, false);
        }
      case ShovelDown(frame):
        if (frame >= 4) {
          state = Sitting(0, !won);
        } else {
          state = ShovelDown(frame + 1);
        }
      case Sitting(frame, true):
        state = Sitting(frame + 1, true);
      case Sitting(frame, false):
        state = Sitting(frame + 1, false);
    }
    setDampeSprite();
  }

  private function setDampeSprite() {
    var index = 0;
    switch (this.state) {
      case Walking(frame, true):
        index = 0;
      case Walking(frame, false):
        index = Math.floor(frame % 4);
      case ShovelDown(frame):
        index = frame + 4;
      case Sitting(frame, true):
        index = 8;
      case Sitting(frame, false):
        index = Math.floor(frame / 2) % 2 + 8;
    }

    var x = (index % 3) * DampeWidth;
    var y = Math.floor(index / 3) * DampeHeight;

    this.dampe.bitmapData.copyPixels(this.dampeSprite, new Rectangle(x, y, x + DampeWidth, y + height), new Point(0, 0));
  }
}
