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
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;
import CellHelper.Cell;

class Game extends Sprite {
  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  public static inline var Width = 84;
  public static inline var Height = 48;
  private static final cellHelper = new CellHelper(Width, Height);

  public static inline var DayFrames = 200;

  var dampe:Dampe;
  var audioManager:AudioManager;
  var statusBar:StatusBar;

  public function init() {
    this.dampe.init();
  };

  public function new(isGameActive:Void->Bool) {
    super();

    this.graphics.beginFill(BlackColor);
    this.graphics.drawRect(0, 0, Width, Height);

    audioManager = new AudioManager();

    Grave.lazyInit();
    Tombstone.lazyInit();
    Ghost.initTextures();

    var church = new Church();
    church.x = 0;
    church.y = 6;
    addChild(church);

    // Enable nokia shader to restrict to monochrome.
    // this.cacheAsBitmap = true;
    this.shader = new NokiaShader();

    // Returns null if offscreen
    var getDampeActionCell = function(intendedPos:Point):Cell {
      var cell = cellHelper.getClosestCell(dampe.x + intendedPos.x, dampe.y + intendedPos.y);
      var dampeRect = dampe.parentSpaceMovementCollider().clone();
      dampeRect.inflate(0, 30);
      {
        var potentialGraveRect = Grave.localSpaceGraveHoleRect();
        var p = cellHelper.getCellCenter(cell);
        potentialGraveRect.offset(p.x, p.y);
        if (potentialGraveRect.intersects(dampeRect)) {
          cell.col += (dampe.isFacingRight() ? 1 : -1);
          if (cell.col < 0 || cell.col > cellHelper.getMaxCellCol()) {
            trace("Attempted to perform action offscreen");
            return null;
          }
        }
      }
      return cell;
    };

    this.statusBar = new StatusBar(3);
    this.addChild(statusBar);

    this.dampe = new Dampe(function(point) {
      trace("digging at", point);
      var digCell = getDampeActionCell(point);
      if (digCell == null) {
        return;
      }
      var worldPos = cellHelper.getCellCenter(digCell);
      var existingGrave = findGraveHoleIntersecting(worldPos);
      if (existingGrave != null) {
        switch existingGrave.getState() {
          case DIG_1:
            existingGrave.setState(DIG_2);
          case DIG_2:
            existingGrave.setState(HOLE);
          case HOLE:
          case SPAWN_PROGRESS_1 | SPAWN_PROGRESS_2:
            var t = getGraveLinkedTombstone(existingGrave);
            if (t != null) {
              t.onDamage();
            }
        }
      } else {
        if (getObjectAtCell(digCell) == null) {
          createGraveAtPoint(worldPos);
        }
      }
    }, function(p:Point):Bool {
      if (this.statusBar.tombStones <= 0) {
        return false;
      }
      var cell = getDampeActionCell(p);
      if (cell == null) {
        return false;
      }
      var existingChild = getObjectAtCell(cell);
      if (existingChild == null) {
        return true;
      }
      switch Type.getClass(existingChild) {
        case Tombstone | Church:
          return false;
        case Grave:
          final g = cast(existingChild, Grave);
          return g.getState() == DIG_1;
      }
      return true;
    }, function(p:Point):Void {
      trace("Placing at ", p);
      var cell = getDampeActionCell(p);
      if (cell == null) {
        return;
      }
      var existingChild = getObjectAtCell(cell);
      if (existingChild != null) {
        removeChild(existingChild);
      }
      var cellOrigin = cellHelper.getCellTopLeft(cell);
      var t = new Tombstone();
      t.x = cellOrigin.x;
      t.y = cellOrigin.y;
      addChild(t);
      this.statusBar.tombStones -= 1;
      sortChildren();
    }, function(p:Point):Bool {
      return isValidDampePosition(p.x, p.y);
    }, isGameActive);
    addChild(dampe);
    dampe.x = 10;
    dampe.y = 10;

    sortChildren();
  }

  private function isValidDampePosition(x:Float, y:Float) {
    var dampeRect = Dampe.localSpaceMovementCollider().clone();
    dampeRect.offset(x, y);
    if (dampeRect.x < 0
      || dampeRect.y < 11
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
        case Tombstone:
          var tRect = Tombstone.localSpacePathingCollider();
          tRect.offset(child.x, child.y);
          if (dampeRect.intersects(tRect)) {
            return false;
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
  }

  private function resolveState() {
    var dampeMonsterCollisionRect = Dampe.localSpaceMonsterCollider();
    dampeMonsterCollisionRect.offset(dampe.x, dampe.y);
    var dampeMovementCollisionRect = Dampe.localSpaceMovementCollider();
    dampeMovementCollisionRect.offset(dampe.x, dampe.y);
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      switch Type.getClass(child) {
        case Ghost:
          var ghostRect = Ghost.localSpaceCollider();
          ghostRect.offset(child.x, child.y);
          if (ghostRect.intersects(dampeMonsterCollisionRect)) {
            if (dampe.spook()) {
              audioManager.playOhNo();
            }
          }
        case Grave:
          var grave = cast(child, Grave);
          switch grave.getState() {
            case SPAWN_PROGRESS_1 | SPAWN_PROGRESS_2:
              var graveRect = Grave.localSpaceGraveHoleRect();
              graveRect.offset(child.x, child.y);
              if (graveRect.intersects(dampeMovementCollisionRect)) {
                var t = getGraveLinkedTombstone(grave);
                if (t != null) {
                  t.onDamage();
                }
              }
            case DIG_1 | DIG_2 | HOLE:
              // nothing
          }
      }
    }

    // If Dampe is stuck, un-stuck him
    if (!isValidDampePosition(dampe.x, dampe.y)) {
      for (dist in 1...20) {
        var resolved = false;
        for (x_dir in [-1, 0, 1]) {
          for (y_dir in [-1, 0, 1]) {
            final dx = x_dir * dist;
            final dy = y_dir * dist;
            if (isValidDampePosition(dampe.x + dx, dampe.y + dy)) {
              trace("un-stuck dampe");
              dampe.x += dx;
              dampe.y += dy;
              resolved = true;
              break;
            }
          }
          if (resolved) {
            break;
          }
        }
        if (resolved) {
          break;
        }
      }
    }
  };

  public function onFrame(frame:Int) {
    this.dampe.onFrame();
    ghostsOnFrame();
    sortChildren();
    resolveState();
    this.statusBar.onFrame(1 - (frame / DayFrames));
  }

  private function getObjectAtCell(cell:Cell):DisplayObject {
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (cellHelper.getClosestCell(child.x, child.y).isSameAs(cell)) {
        switch Type.getClass(child) {
          case Grave|Tombstone|Church:
            return child;
        }
      }
    }
    return null;
  }

  // Result may be null
  private function getGraveLinkedTombstone(g:Grave): Tombstone {
    final gCell = cellHelper.getClosestCell(g.x, g.y);
    if (gCell.row == 0) {
      return null;
    }
    final aboveCell = new Cell(gCell.row - 1, gCell.col);
    final above = getObjectAtCell(aboveCell);
    if (above == null || Type.getClass(above) != Tombstone) {
      return null;
    }
    return cast(above, Tombstone);
  }

  public function onBeginDay() {
    resolveState();

    // Reset dampe
    this.statusBar.tombStones = 3;
    this.dampe.x = 0;
    this.dampe.y = 14;
    this.dampe.unSpook();
    this.dampe.resetState();
  }

  public function onDayEnd(): Int {
    return progressGraves();
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

  // Painters algo. Tombstones + Dampe are sorted based on "base y" so dampe is
  // behind some tombstones and in front of others.
  // Ghosts and status bar are on top of everything.
  function sortChildren() {
    final tombstoneRect = Tombstone.localSpacePathingCollider();
    final dampeRect = Dampe.localSpaceMovementCollider();
    var getChildZ = function(child:DisplayObject) {
      switch Type.getClass(child) {
        case Grave:
          return 0.0;
        case Tombstone:
          return child.y + tombstoneRect.y + tombstoneRect.height;
        case Dampe:
          return child.y + dampeRect.y + dampeRect.height;
        case Ghost:
          return 999 + child.y;
        case StatusBar:
          return 10000 + child.y;
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

  function createGhostAtPoint(x:Float, y:Float):Ghost {
    var collider = Ghost.localSpaceCollider();
    var ghost = new Ghost();
    ghost.x = x + collider.x - collider.width / 2;
    ghost.y = y + collider.y - collider.height / 2;
    addChild(ghost);
    sortChildren();

    return ghost;
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
        if (g.hitTestPoint(point.x, point.y)) {
          return g;
        }
      }
    }
    trace("no grave found at ", point);
    return null;
  }

  // Returns number of newly "SANCTIFIED" graves.
  function progressGraves(): Int {
    var count = 0;
    var gravesToRemove:Array<Grave> = [];
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (Type.getClass(child) == Grave) {
        var g:Grave = cast(child, Grave);
        var t = getGraveLinkedTombstone(g);
        if (t != null && t.getState() == NORMAL) {
          switch g.getState() {
            case HOLE:
              g.setState(SPAWN_PROGRESS_1);
            case SPAWN_PROGRESS_1:
              g.setState(SPAWN_PROGRESS_2);
            case SPAWN_PROGRESS_2:
              t.setState(SANCTIFIED);
              gravesToRemove.push(g);
              createGhostAtPoint(g.x, g.y);
              count++;
            case DIG_1|DIG_2:
              // nothing
          }
        }
      }
    }
    for (g in gravesToRemove) {
      removeChild(g);
    }
    return count;
  }
}
