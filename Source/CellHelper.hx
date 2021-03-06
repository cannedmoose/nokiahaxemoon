package;

import openfl.geom.Point;
import openfl.geom.Rectangle;

class Cell {
  public var row:Int;
  public var col:Int;

  public function new(row:Int, col:Int) {
    this.row = row;
    this.col = col;
  }

  public function isSameAs(other:Cell): Bool {
    return this.row == other.row && this.col == other.col;
  }
}

class CellHelper {
  public static final TOP_BORDER = 6;
  public static final CELL_HEIGHT = 7;
  public static final CELL_WIDTH = 7;
  public static function CELL_SIZE() {
    return new Rectangle(0, 0, CELL_WIDTH + 1, CELL_HEIGHT + 1);
  }

  private final pixelWidth:Int;
  private final pixelHeight:Int;

  public function new(pixelWidth:Int, pixelHeight:Int) {
    this.pixelWidth = pixelWidth;
    this.pixelHeight = pixelHeight;
  }

  public function getCellCenter(cell:Cell): Point {
    return new Point(
      cell.col * CELL_WIDTH + cast(CELL_WIDTH, Float) / 2,
      cell.row * CELL_HEIGHT + cast(CELL_HEIGHT, Float) / 2 + TOP_BORDER
    );
  }

  public function getCellTopLeft(cell:Cell): Point {
    return new Point(
      cell.col * CELL_WIDTH,
      cell.row * CELL_HEIGHT + TOP_BORDER);
  }

  public function getMaxCellCol(): Int {
    return Math.round(pixelWidth / CELL_WIDTH);
  }

  public function getClosestCell(x:Float, y:Float): Cell {
    return new Cell(getRow(y), getCol(x));
  }

  public function getClosestCellP(p:Point): Cell {
    return getClosestCell(p.x, p.y);
  }

  private function getRow(y:Float): Int {
    return clamp(
        Math.floor((y - TOP_BORDER) / CELL_HEIGHT),
        0,
        Math.round((pixelHeight - TOP_BORDER) / CELL_HEIGHT));
  }

  private function getCol(x:Float): Int {
    return clamp(
        Math.floor(x / CELL_WIDTH),
        0,
        getMaxCellCol());
  }

  private static function clamp(v:Int, low:Int, high:Int): Int {
    return v < low ? low : (v > high ? high : v);
  }
}
