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

class EndOfDayData {
  public final gravesFilled:Int;
  public final ghostsReleased:Int;

  public function new(gravesFilled:Int, ghostsReleased:Int) {
    this.gravesFilled = gravesFilled;
    this.ghostsReleased = ghostsReleased;
  }
}

enum ActionType {
  DIG;
  PLACE;
}

class Game extends Sprite {
  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  public static inline var Width = 84;
  public static inline var Height = 48;
  private static final cellHelper = new CellHelper(Width, Height);

  public var dayFrames = 1;

  private var ghostsReleasedToday = 0;

  var dampe:Dampe;
  var audioManager:AudioManager;
  var statusBar:StatusBar;

  var cachedActionRow:Map<ActionType, Int> = new Map();

  public function init() {
    this.dampe.init();
  };

  public function new(audioManager:AudioManager, isGameActive:Void->Bool) {
    super();

    this.graphics.beginFill(BlackColor);
    this.graphics.drawRect(0, 0, Width, Height);

    this.audioManager = audioManager;

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

    // Basically, -1 == bad, 0 == neutral, 1 == positive
    var getActionScore = function(action:ActionType, objectAtLocation:DisplayObject):Float {
      if (objectAtLocation == null)
        return 1;
      switch action {
        case DIG:
          switch Type.getClass(objectAtLocation) {
            case Church:
              return 0;
            case Grave:
              var g = cast(objectAtLocation, Grave);
              switch g.getState() {
                case DIG_1 | DIG_2:
                  return 1;
                case HOLE:
                  return 0;
                case SPAWN_PROGRESS_1 | SPAWN_PROGRESS_2:
                  return -1;
              }
            case Tombstone:
              switch cast(objectAtLocation, Tombstone).getState() {
                case NORMAL:
                  return -1;
                case DAMAGED:
                  return 0;
                case SANCTIFIED:
                  return 1;
              }
            default:
              // Shouldn't happen.
          }
        case PLACE:
          switch Type.getClass(objectAtLocation) {
            case Church | Grave:
              return 0;
            case Tombstone:
              return (cast(objectAtLocation, Tombstone).getState() == DAMAGED) ? 1 : 0;
            default:
              // Shouldn't happen.
          }
      }
      // Shouldn't get here... I think
      return 0;
    };

    var shouldAllowActionInOwnCell = function(action:ActionType, objectAtLocation:DisplayObject): Bool {
      if (objectAtLocation == null) {
        return false;
      }
      if (Type.getClass(objectAtLocation) != Tombstone) {
        return false;
      }
      return cast(objectAtLocation, Tombstone).getState() == SANCTIFIED;
    };

    // Returns null if offscreen
    var getDampeActionCell = function(intendedPos:Point, action:ActionType):Cell {
      var bestCell:Cell = null;
      var bestScore:Float = -2;
      var dampeRect = dampe.parentSpaceMovementCollider().clone();
      dampeRect.inflate(0, 30);
      for (searchDist in 0...3) {
        for (searchDir in [-1, 1]) {
          var cell = cellHelper.getClosestCell(dampe.x + intendedPos.x, dampe.y + intendedPos.y + searchDist * searchDir);
          var potentialCellRect = CellHelper.CELL_SIZE();
          var p = cellHelper.getCellTopLeft(cell);
          potentialCellRect.offset(p.x, p.y);
          if (potentialCellRect.intersects(dampeRect) && !shouldAllowActionInOwnCell(action, getObjectAtCell(cell))) {
            cell.col += (dampe.isFacingRight() ? 1 : -1);
            if (cell.col < 0 || cell.col > cellHelper.getMaxCellCol()) {
              trace("Attempted to perform action offscreen");
              return null;
            }
          }
          var score = getActionScore(action, getObjectAtCell(cell));
          if (cachedActionRow.exists(action) && cell.row != cachedActionRow.get(action)) {
            score -= 0.1;
          }
          if (score > bestScore) {
            bestScore = score;
            bestCell = cell;
          }
          if (bestScore == 1) {
            // Max score, just return.
            return bestCell;
          }
        }
      }
      return bestCell;
    };

    this.statusBar = new StatusBar(3);
    this.addChild(statusBar);

    this.dampe = new Dampe(function(point) {
      trace("digging at", point);
      var digCell = getDampeActionCell(point, DIG);
      if (digCell == null) {
        return;
      }
      var existingObject = getObjectAtCell(digCell);
      if (existingObject != null) {
        switch Type.getClass(existingObject) {
          case Grave:
            var existingGrave = cast(existingObject, Grave);
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
          case Tombstone:
            var t = cast(existingObject, Tombstone);
            digTombstone(t);
        }
      } else {
        var worldPos = cellHelper.getCellCenter(digCell);
        createGraveAtPoint(worldPos);
      }
      cachedActionRow[DIG] = digCell.row;
    }, function(p:Point):Bool {
      if (this.statusBar.tombStones <= 0) {
        return false;
      }
      var cell = getDampeActionCell(p, PLACE);
      if (cell == null) {
        return false;
      }
      var existingChild = getObjectAtCell(cell);
      if (existingChild == null) {
        return true;
      }
      switch Type.getClass(existingChild) {
        case Tombstone:
          return cast(existingChild, Tombstone).getState() == DAMAGED;
        case Church:
          return false;
        case Grave:
          final g = cast(existingChild, Grave);
          return g.getState() == DIG_1;
      }
      return true;
    }, function(p:Point):Void {
      trace("Placing at ", p);
      var cell = getDampeActionCell(p, PLACE);
      if (cell == null) {
        return;
      }
      cachedActionRow[PLACE] = cell.row;
      var existingChild = getObjectAtCell(cell);
      if (existingChild != null) {
        switch Type.getClass(existingChild) {
          case Tombstone:
            var t = cast(existingChild, Tombstone);
            if (t.getState() == DAMAGED) {
              t.setState(NORMAL, t.getLinkedGhost());
            }
            this.statusBar.tombStones -= 1;
            return;
          default:
            removeChild(existingChild);
        }
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
    }, isGameActive, function(dx:Float, dy:Float) {
      if (dy != 0) {
        cachedActionRow.clear();
      }
    });
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
    var dampeChurchCollisionRect = Dampe.localSpaceChurchCollider();
    dampeChurchCollisionRect.offset(dampe.x, dampe.y);
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
        case Church:
          var churchRect = Church.localCollider();
          churchRect.offset(child.x, child.y);
          if (churchRect.intersects(dampeChurchCollisionRect)) {
            this.statusBar.tombStones = Math.round(Math.min(this.statusBar.tombStones + 1, 3));
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
    this.statusBar.onFrame(1 - (frame / dayFrames));
  }

  private function digTombstone(t:Tombstone) {
    switch t.getState() {
      case NORMAL | DAMAGED:
        t.onDamage();
      case SANCTIFIED:
        ghostsReleasedToday++;
        removeChild(t.getLinkedGhost());
        removeChild(t);
        audioManager.playSuccess();
    }
  }

  private function getObjectAtCell(cell:Cell):DisplayObject {
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      var childCell = cellHelper.getClosestCell(child.x, child.y);
      if (childCell.isSameAs(cell)) {
        switch Type.getClass(child) {
          case Grave | Tombstone | Church:
            return child;
        }
      }
      if (Type.getClass(child) == Church) {
        if (new Cell(childCell.row, childCell.col + 1).isSameAs(cell)
          || new Cell(childCell.row + 1, childCell.col).isSameAs(cell)
          || new Cell(childCell.row + 1, childCell.col + 1).isSameAs(cell)) {
          return child;
        }
      }
    }
    return null;
  }

  // Result may be null
  private function getGraveLinkedTombstone(g:Grave):Tombstone {
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

  public function onBeginDay(dayFrames:Int) {
    resolveState();
    ghostsReleasedToday = 0;
    cachedActionRow.clear();

    this.dayFrames = dayFrames;

    // Reset dampe
    this.statusBar.tombStones = 3;
    this.dampe.x = 0;
    this.dampe.y = 14;
    this.dampe.unSpook();
    this.dampe.resetState();
  }

  public function onDayEnd():EndOfDayData {
    var filledGraves = progressGraves();
    return new EndOfDayData(filledGraves, ghostsReleasedToday);
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

  // Returns number of newly filled graves.
  function progressGraves():Int {
    var gravesFilled = 0;
    var gravesToRemove:Array<Grave> = [];
    for (i in 0...numChildren) {
      var child = getChildAt(i);
      if (Type.getClass(child) == Grave) {
        var g:Grave = cast(child, Grave);
        var t = getGraveLinkedTombstone(g);
        if (t != null && t.getState() == NORMAL) {
          switch g.getState() {
            case HOLE:
              gravesFilled++;
              g.setState(SPAWN_PROGRESS_1);
            case SPAWN_PROGRESS_1:
              g.setState(SPAWN_PROGRESS_2);
            case SPAWN_PROGRESS_2:
              var ghost = createGhostAtPoint(g.x, g.y);
              t.setState(SANCTIFIED, ghost);
              gravesToRemove.push(g);
            case DIG_1 | DIG_2:
              // nothing
          }
        }
      }
    }
    for (g in gravesToRemove) {
      removeChild(g);
    }
    return gravesFilled;
  }
}
