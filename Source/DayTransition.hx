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

  public var day:Int;
  public var graves:Int;
  public var crosses:Int;
  public var money:Int;

  private var daySprite:DisplayNumber;
  private var gravesSprite:DisplayNumber;
  private var crossSprite:DisplayNumber;
  private var moneySprite:DisplayNumber;
  private var totalDays:DisplayNumber;

  public function update(day, graves, crosses, money) {
    trace(day, graves, money);
    this.day = day;
    this.graves = graves;
    this.money = money;
    this.crosses = crosses;
    daySprite.update(day);
    gravesSprite.update(graves);
    crossSprite.update(crosses);
    moneySprite.update(money);
  }

  public function new(day, graves, crosses, money) {
    super();
    this.sprite = new Bitmap(Assets.getBitmapData("Assets/transition.png"));
    addChild(this.sprite);
    daySprite = new DisplayNumber(day, 2);
    daySprite.x = 30;
    daySprite.y = 2;
    addChild(daySprite);

    gravesSprite = new DisplayNumber(graves, 1);
    gravesSprite.x = 20;
    gravesSprite.y = 21;
    addChild(gravesSprite);

    crossSprite = new DisplayNumber(crosses, 1);
    crossSprite.x = 20;
    crossSprite.y = 35;
    addChild(crossSprite);

    moneySprite = new DisplayNumber(money, 3);
    moneySprite.x = 44;
    moneySprite.y = 25;
    addChild(moneySprite);

    totalDays = new DisplayNumber(13, 2);
    totalDays.x = 64;
    totalDays.y = 2;
    addChild(totalDays);
  }

  public function onFrame() {}
}
