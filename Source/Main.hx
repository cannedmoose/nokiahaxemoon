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

class Main extends Sprite {
	public static inline var WhiteColor = 0xc7f0d8;
	public static inline var BlackColor = 0x43523d;

	public static inline var Width = 84;
	public static inline var Height = 48;

	public static inline var DayFrames = 200;

	public function new() {
		super();

		Grave.lazyInit();
    Ghost.initTextures();

		// Enable nokie shader to restrict to monochrome.
		// this.cacheAsBitmap = true;
		this.shader = new NokiaShader();
		var dampe:Dampe;
		dampe = new Dampe(function(point) {
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
      // TODO movement validation at edge of screen
      var dampeRect = Dampe.getLocalSpaceCollider().clone();
      dampeRect.offset(p.x, p.y);
      for (i in 0...numChildren) {
        var child = getChildAt(i);
        if (Type.getClass(child) == Grave) {
          var g:Grave = cast(child, Grave);
          var gRect = g.localSpacePathingCollisionRect();
          if (gRect != null) {
            gRect = gRect.clone();
            gRect.offset(g.x, g.y);
            if (dampeRect.intersects(gRect)) {
              return false;
            }
          }
        }
      }
      return true;
    });
		addChild(dampe);
		dampe.init();
		dampe.x = 10;
		dampe.y = 10;

		var frameCounter = 0;
		this.graphics.beginFill(WhiteColor);
		this.graphics.drawRect(0, 0, Width, 2);

		var cacheTime = getTimer();
		this.addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			if (deltaTime > 200) {
				dampe.onFrame();
        ghostsOnFrame();
        sortChildren();
				frameCounter += 1;
				this.graphics.beginFill(BlackColor);
				this.graphics.drawRect(Width - Width * (frameCounter / DayFrames), 0, Width * (frameCounter / DayFrames), 2);
				if (frameCounter >= DayFrames) {
					fillEmptyGraves();
					this.graphics.beginFill(WhiteColor);
					this.graphics.drawRect(0, 0, Width, 2);
					frameCounter = 0;
				}
				cacheTime = currentTime;
			}
		});

    var testGhost = new Ghost();
    testGhost.x = 60;
    testGhost.y = 20;
    addChild(testGhost);

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 9999, new SoundTransform(0.6));

    sortChildren();
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
    final dampeRect = Dampe.getLocalSpaceCollider();
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
      if (a_z == b_z) return 0;
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

	function createGraveAtPoint(point:Point): Grave {
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
