import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.BitmapDataChannel;
import openfl.display.Shape;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.Lib.getTimer;
import openfl.ui.Keyboard;
import openfl.events.Event;
import openfl.events.KeyboardEvent;

// Spritesheet is 3x4 with 12 filled slots
// standing/walking slots with shovel raised/lowered
// 0 - standing
// 1 - walking
// 2 - standing
// 3 - walking
// 4 transition
// 5:10 - digging
// 10:12 - placing

enum DampeState {
  Standing(frame:Int);
  Walking(frame:Int);
  Digging(frame:Int);
  Placing(frame:Int);
}

enum KeyState {
  PRESSED;
  RELEASED_BUT_UNPROCESSED;
  RELEASED;
}

class Dampe extends Sprite {
  public static inline var Width = 14;
  public static inline var Height = 12;
  public static final SPOOK_DURATION_FRAMES = 40;

  var state:DampeState;
  var spriteSheet:BitmapData;
  var sprite:Bitmap;
  var direction:Point;
  var flip = false;
  var digCallback:Point->Void;
  var movementValidationCallback:Point->Bool;
  var isGameActive:Void->Bool;
  var placeGraveValidationCallback:Point->Bool;
  var placeGraveCallback:Point->Void;
  var movementListener:(dx:Float, dy:Float) -> Void;

  var spookedCountdown = 0;
  var skipFrame = false;

  var pressedKeys:Map<Int, KeyState> = new Map();

  public function new(digCallback:Point->Void, placeGraveValidationCallback:Point->Bool, placeGraveCallback:Point->Void,
      movementValidationCallback:Point->Bool, isGameActive:Void->Bool, movementListener:(dx:Float, dy:Float) -> Void) {
    super();

    this.resetState();

    this.spriteSheet = Assets.getBitmapData("Assets/dampe_alt.png");
    this.sprite = new Bitmap(new BitmapData(Width, Height, true, 0xFFFFFFFF));
    this.direction = new Point(0, 0);
    this.digCallback = digCallback;
    this.placeGraveCallback = placeGraveCallback;
    this.placeGraveValidationCallback = placeGraveValidationCallback;
    this.movementValidationCallback = movementValidationCallback;
    this.isGameActive = isGameActive;
    this.movementListener = movementListener;
    addChild(this.sprite);
    this.updateSprite();
  }

  public function isFacingRight():Bool {
    return flip;
  }

  public function init() {
    stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e) {
      pressedKeys[e.keyCode] = PRESSED;
    });
    stage.addEventListener(KeyboardEvent.KEY_UP, function(e) {
      pressedKeys[e.keyCode] = (isGameActive() && isKeyPressed(e.keyCode)) ? RELEASED_BUT_UNPROCESSED : RELEASED;
    });
  }

  public static function localSpaceMonsterCollider():Rectangle {
    return new Rectangle(8, 5, 3, 7);
  }

  public static function localSpaceMovementCollider():Rectangle {
    return new Rectangle(8, 11, 3, 1);
  }

  public static function localSpaceChurchCollider():Rectangle {
    return new Rectangle(7, 5, 3, 7);
  }

  public function parentSpaceMovementCollider():Rectangle {
    var rect = localSpaceMovementCollider();
    rect.offset(this.x, this.y);
    return rect;
  }

  public function spook():Bool {
    if (spookedCountdown <= 0) {
      trace("spooky!");
      spookedCountdown = SPOOK_DURATION_FRAMES;
      skipFrame = true;
      return true;
    }
    return false;
  }

  public function unSpook() {
    skipFrame = false;
    spookedCountdown = 0;
  }

  public function resetState() {
    this.state = Standing(0);
  }

  public function onFrame() {
    handleInput();

    if (spookedCountdown > 0) {
      spookedCountdown--;
    }
    if (spookedCountdown > 0) {
      this.sprite.alpha = skipFrame ? 0 : 1;

      skipFrame = !skipFrame;
      if (!skipFrame) {
        return;
      }
    } else {
      this.sprite.alpha = 1;
    }

    switch (this.state) {
      case Standing(frame):
        this.state = Standing((frame + 1) % 4);
      case Walking(frame):
        // Make sure direction has been pressed.
        if (this.direction.x == 0 && this.direction.y == 0) {
          this.state = Standing((frame + 1) % 4);
        } else {
          // Actually take a step and reset direction
          if (movementValidationCallback(new Point(this.x + direction.x, this.y + direction.y))) {
            this.x += this.direction.x;
            this.y += this.direction.y;
            this.movementListener(direction.x, direction.y);
          }
          this.direction.x = 0;
          this.direction.y = 0;
          this.state = Walking((frame + 1) % 4);
        }

      case Digging(frame):
        if (frame == 6) {
          this.state = Standing(0);
        } else {
          if (frame == 2) {
            // Spawn hole
            var actionPoint = flip ? new Point(13, 10) : new Point(3, 10);
            this.digCallback(actionPoint);
          }
          this.state = Digging((frame + 1) % 7);
        }
      case Placing(frame):
        var actionPoint = flip ? new Point(14, 8) : new Point(2, 8);
        if (frame == 0) {
          trace(this.placeGraveValidationCallback(actionPoint));
          if (!this.placeGraveValidationCallback(actionPoint)) {
            this.state = Standing(0);
          } else {
            this.state = Placing(1);
          }
        } else if (frame == 2) {
          this.placeGraveCallback(actionPoint);
          this.state = Placing((frame + 1) % 4);
        } else if (frame == 3) {
          this.state = Standing(0);
        } else {
          this.state = Placing((frame + 1) % 4);
        }
    }
    this.updateSprite();
  }

  private function isKeyPressed(keyCode:Int):Bool {
    var x:Null<KeyState> = pressedKeys.get(keyCode);
    return x != null && (x == PRESSED || x == RELEASED_BUT_UNPROCESSED);
  }

  private function handleInput() {
    switch (this.state) {
      case Standing(frame):
        if (isKeyPressed(Keyboard.W)) {
          this.direction.y = -1;
          this.state = Walking(Math.floor(frame / 2) * 2);
        } else if (isKeyPressed(Keyboard.S)) {
          this.direction.y = 1;
          this.state = Walking(Math.floor(frame / 2) * 2);
        } else if (isKeyPressed(Keyboard.A)) {
          this.direction.x = -1;
          this.flip = false;
          this.state = Walking(Math.floor(frame / 2) * 2);
        } else if (isKeyPressed(Keyboard.D)) {
          this.direction.x = 1;
          this.flip = true;
          this.state = Walking(Math.floor(frame / 2) * 2);
        } else if (isKeyPressed(Keyboard.E)) {
          this.state = Digging(0);
        } else if (isKeyPressed(Keyboard.Q)) {
          this.state = Placing(0);
        }
      case Walking(frame):
        if (isKeyPressed(Keyboard.W)) {
          this.direction.y = -1;
          this.direction.x = 0;
        } else if (isKeyPressed(Keyboard.S)) {
          this.direction.y = 1;
          this.direction.x = 0;
        } else if (isKeyPressed(Keyboard.A)) {
          this.direction.x = -1;
          this.direction.y = 0;
          this.flip = false;
        } else if (isKeyPressed(Keyboard.D)) {
          this.direction.x = 1;
          this.direction.y = 0;
          this.flip = true;
        } else if (isKeyPressed(Keyboard.E)) {
          this.state = Digging(0);
        } else if (isKeyPressed(Keyboard.Q)) {
          this.state = Placing(0);
        }
      case Digging(frame):
      // No-op
      case Placing(frame):
        // No-op
    }

    for (key in pressedKeys.keys()) {
      if (pressedKeys[key] == RELEASED_BUT_UNPROCESSED) {
        pressedKeys[key] = RELEASED;
      }
    }
  }

  private function updateSprite() {
    var index = 0;
    switch (this.state) {
      case Standing(frame):
        index = Math.floor(frame / 2) * 2;
      case Walking(frame):
        index = frame;
      case Digging(frame):
        index = frame + 3;
      case Placing(frame):
        if (frame == 0 || frame == 3) {
          index = 4;
        } else {
          index = 10 + frame - 1;
        }
    }
    var x = (index % 3) * Width;

    var y = Math.floor(index / 3) * Height;
    this.sprite.bitmapData.copyPixels(this.spriteSheet, new Rectangle(x, y, x + Width, y + height), new Point(0, 0));
    if (this.flip) {
      this.sprite.x = Width + 4;
      this.sprite.scaleX = -1;
    } else {
      this.sprite.scaleX = 1;
      this.sprite.x = 0;
    }
  }
}
