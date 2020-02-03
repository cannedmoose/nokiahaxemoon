import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class DisplayNumber extends Sprite {
  public static inline var Width = 6;
  public static inline var Height = 11;

  var spriteSheet:BitmapData;
  var sprite:Bitmap;
  public var number:Int;
  var fill:Int;

  public function new(number:Int, fill:Int = 1) {
    super();
    this.number = number;
    this.fill = fill;
    this.spriteSheet = Assets.getBitmapData("Assets/numbers.png");
    this.sprite = new Bitmap(new BitmapData(Width * fill, Height * fill, true, 0xc7f0d8));
    addChild(this.sprite);
    this.updateSprite();
  }

  public function update(newNumber: Int) {
    this.number = newNumber;
    this.updateSprite();
  }

  private function updateSprite() {
    var n: Float = this.number;
    var digits = Math.ceil(Math.log(n) / Math.log(10));
    if (digits < this.fill) {
      digits = fill;
    }
    this.sprite.bitmapData = new BitmapData((Width + 1) * (digits), Height, true, 0xc7f0d8);
    while (digits-- > 0) {
      var digit:Int = Math.floor(n) % 10;
      n = n / 10;
      this.sprite.bitmapData.copyPixels(this.spriteSheet, new Rectangle(digit * Width, 0, Width, Height), new Point((digits) * (1 + Width), 0));
    }
  }
}
