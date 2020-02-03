package;

import Shaders.NokiaShader;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.display.DisplayObjectShader;
import openfl.display.DisplayObject;
import openfl.display.BlendMode;
import openfl.events.Event;
import openfl.Lib.getTimer;
import openfl.media.Sound;
import openfl.media.SoundTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class Game extends Sprite {
  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  public static inline var Width = 84;
  public static inline var Height = 48;

  public static inline var DayFrames = 200;
  var dampe:Dampe;

  public function init() {
    this.dampe.init();
  };

  public function new(isGameActive:Void->Bool) {
    super();

    this.graphics.beginFill(BlackColor);
    this.graphics.drawRect(0, 0, Width, Height);

      Grave.lazyInit();
    Ghost.initTextures();

    var church = new Church();
    church.x = 0;
    church.y = 3;
    addChild(church);

    // Enable nokia shader to restrict to monochrome.
    // this.cacheAsBitmap = true;
    this.shader = new NokiaShader();

    
    this.dampe = new Dampe(function(point) {
      trace("digging at", point);
      var worldPos = new Point(dampe.x + point.x, dampe.y + point.y);
      var existingGrave = findGraveHoleIntersecting(worldPos);
      if (existingGrave != null) {
        switch existingGrave.getState() {
          case DIG_1:
            existingGrave.setState(DIG_2);
          case DIG_2:
            existingGrave.setState(FRESH);
          case FRESH:
          case FULL:
        }
      } else {
        createGraveAtPoint(worldPos);
      }
    }, function(p:Point): Bool {
      var dampeRect = Dampe.localSpaceMovementCollider().clone();
      dampeRect.offset(p.x, p.y);
      if (dampeRect.x < 0 || dampeRect.y < 5
          || (dampeRect.x + dampeRect.width > Width)
          || (dampeRect.y + dampeRect.height > Height)) {
        return false;
      }
      for (i in 0...numChildren) {
        var child = getChildAt(i);
        switch Type.getClass(child) {
          case Grave:
            var g:Grave = cast(child, Grave);
            var gRect = g.localSpacePathingCollisionRect();
            if (gRect != null) {
              gRect = gRect.clone();
              gRect.offset(g.x, g.y);
              if (dampeRect.intersects(gRect)) {
                return false;
              }
            }
          case Church:
            var rect = Church.localCollider().clone();
            rect.offset(child.x, child.y);
            if (dampeRect.intersects(rect)) {
              return false;
            }
        }
      }
      return true;
    }, isGameActive);
    addChild(dampe);
    dampe.x = 10;
    dampe.y = 10;

    var testGhost = new Ghost();
    testGhost.x = 60;
    testGhost.y = 20;
    addChild(testGhost);

    var music:Sound = Assets.getSound("Assets/k2lu.mp3");
    music.play(0, 9999, new SoundTransform(0.6));

    sortChildren();
  }

  private function resolveState() {
    var dampeMonsterCollisionRect = Dampe.localSpaceMonsterCollider();
    dampeMonsterCollisionRect.offset(dampe.x, dampe.y);
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      switch Type.getClass(child) {
        case Ghost:
          var ghostRect = Ghost.localSpaceCollider();
          ghostRect.offset(child.x, child.y);
          if (ghostRect.intersects(dampeMonsterCollisionRect)) {
            dampe.spook();
          }
      }
    }
  };

  public function onFrame(frame:Int) {
    // Draw timer
    this.graphics.beginFill(BlackColor);
    this.graphics.drawRect(Width - Width * (frame / DayFrames), 0, Width * (frame / DayFrames), 2);

    this.dampe.onFrame();
    ghostsOnFrame();
    sortChildren();
    resolveState();
  }

  public function onBeginDay() {
    fillEmptyGraves();
    
    // Reset timer area
    this.graphics.beginFill(WhiteColor);
    this.graphics.drawRect(0, 0, Width, 2);
  }

  public function onDayEnd() {
  }

  public function nGraves(): Int {
    var n = 0;
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (Type.getClass(child) == Grave) {
        var g:Grave = cast(child, Grave);
        trace(g.getState());
        if (g.getState() == FRESH) {
          n = n + 1;
        }
      }
    }
    return n;
  }

  function ghostsOnFrame() {
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      switch Type.getClass(child) {
        case Ghost:
          cast(child, Ghost).onFrame();
        default:
      }
    }
  }

  // Painters algo. Graves + Dampe are sorted based on "base y" so dampe is
  // behind some tombstones and in front of others.
  // Ghosts are on top of everything.
  function sortChildren() {
    final tombstoneRect = Grave.localSpaceTombstoneRect();
    final dampeRect = Dampe.localSpaceMovementCollider();
    var getChildZ = function(child:DisplayObject) {
      switch Type.getClass(child) {
        case Grave:
          return child.y + tombstoneRect.y + tombstoneRect.height;
        case Dampe:
          return child.y + dampeRect.y + dampeRect.height;
        case Ghost:
          return 999;
        default:
          return -1;
      }
    };
    var sortFn = function(a:DisplayObject, b:DisplayObject) {
      final a_z = getChildZ(a);
      final b_z = getChildZ(b);
      if (a_z == b_z)
        return 0;
      return (a_z > b_z) ? 1 : -1;
    };
    var sortArray = new Array<DisplayObject>();
    for (i in 0...numChildren) {
      sortArray.push(getChildAt(i));
    }
    sortArray.sort(sortFn);
    for (i in 0...sortArray.length) {
      setChildIndex(sortArray[i], i);
    }
  }

  function createGraveAtPoint(point:Point):Grave {
    var grave = new Grave();
    grave.x = point.x;
    grave.y = point.y;
    addChild(grave);
    sortChildren();

    return grave;
  }

  // Result may be null
  function findGraveHoleIntersecting(point:Point):Grave {
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (Type.getClass(child) == Grave) {
        var g:Grave = cast(child, Grave);
        if (g.intersectsHole(point)) {
          return g;
        }
      }
    }
    return null;
  }

  function fillEmptyGraves() {
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (Type.getClass(child) == Grave) {
        var g:Grave = cast(child, Grave);
        if (g.getState() == FRESH) {
          g.setState(FULL);
        }
      }
    }
  }
}
