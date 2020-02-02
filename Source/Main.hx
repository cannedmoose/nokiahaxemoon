package;

import Shaders.NokiaShader;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.filters.ShaderFilter;
import openfl.display.DisplayObjectShader;
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
      var dampeRect = dampe.getLocalSpaceCollider().clone();
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

    // Sorts dampe for going infront of or behind tombstones.
    var sortDampe = function() {
      removeChild(dampe);
      var newDampeIndex = 0;
      var dampBase = dampe.y + dampe.getLocalSpaceCollider().y + dampe.getLocalSpaceCollider().height;
      var tombstoneRect = Grave.localSpaceTombstoneRect();
      for (i in 0...numChildren) {
        newDampeIndex = i;
        var child = getChildAt(i);
        if (Type.getClass(child) == Grave) {
          var g:Grave = cast(child, Grave);
          if (dampBase <= (g.y + tombstoneRect.y + tombstoneRect.height)) {
            break;
          }
        }
        if (i == numChildren - 1) {
          newDampeIndex = numChildren;
        }
      }
      addChildAt(dampe, newDampeIndex);
    };

		var cacheTime = getTimer();
		this.addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			if (deltaTime > 200) {
				dampe.onFrame();
        sortDampe();
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

		var music:Sound = Assets.getSound("Assets/k2lu.mp3");
		music.play(0, 9999, new SoundTransform(0.6));
	}

	function createGraveAtPoint(point:Point): Grave {
		var grave = new Grave();
		grave.x = point.x;
		grave.y = point.y;

    // Find index to insert grave. Should be ordered by increasing y.
    var indexToAddAt = 0;
		for (i in 0...numChildren) {
      indexToAddAt = i;
			var child = getChildAt(i);
			if (Type.getClass(child) == Grave) {
				var g:Grave = cast(child, Grave);
        if (g.y > grave.y) {
          break;
        }
			}
      if (i == numChildren - 1) {
        indexToAddAt = numChildren;
      }
		}
		addChildAt(grave, indexToAddAt);
		for (i in 0...numChildren) {
      var child = getChildAt(i);
    }
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
