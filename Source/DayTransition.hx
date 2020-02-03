import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.geom.Point;

class DayTransition extends Sprite {
  public static inline var Width = 84;
  public static inline var Height = 48;

  var sprite:Bitmap;
  public var day: Int;
  public var graves: Int;
  public var money: Int;

  private var daySprite: DisplayNumber;
  private var gravesSprite: DisplayNumber;
  private var moneySprite: DisplayNumber;

  public function update(day, graves, money) {
    trace(day, graves, money);
    this.day = day;
    this.graves = graves;
    this.money = money;
    daySprite.update(day);
    gravesSprite.update(graves);
    moneySprite.update(money);
  }

  public function new(day, graves, money) {
    super();
    this.sprite = new Bitmap(Assets.getBitmapData("Assets/transition.png"));
    addChild(this.sprite);
    daySprite = new DisplayNumber(day, 2);
    daySprite.x = 30;
    daySprite.y = 6;
    addChild(daySprite);

    gravesSprite = new DisplayNumber(graves, 2);
    gravesSprite.x = 68;
    gravesSprite.y = 8;
    addChild(gravesSprite);

    moneySprite = new DisplayNumber(money, 4);
    moneySprite.x = 14;
    moneySprite.y = 27;
    addChild(moneySprite);
  }

  public function onFrame() {}
}
