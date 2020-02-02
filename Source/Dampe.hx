import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.BitmapDataChannel;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.Lib.getTimer;
import openfl.ui.Keyboard;
import openfl.events.Event;
import openfl.events.KeyboardEvent;

// Spritesheet is 3x3 with 8 filled slots
// from top left going right
enum State {
	Standing(frame:Int); // First 2 frames
	Digging(frame:Int); // next 6 frames
}

class Dampe extends Sprite {
	public static inline var Width = 13;
	public static inline var Height = 12;

	var state:State;
	var spriteSheet:BitmapData;
	var sprite:BitmapData;
	var direction:Point;

	public function new() {
		super();

		this.state = Standing(0);
		this.spriteSheet = Assets.getBitmapData("Assets/dampe.png");
		this.sprite = new BitmapData(Width, Height, true, 0xFFFFFFFF);
		this.direction = new Point(0, 0);
		addChild(new Bitmap(this.sprite));
		this.updateSprite();
	}

	public function init() {
		var cacheTime = getTimer();
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		this.addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			if (deltaTime > 500) {
				switch (this.state) {
					case Standing(frame):
						this.state = Standing((frame + 1) % 2);
						this.x += this.direction.x;
						this.y += this.direction.y;
					case Digging(frame):
						this.state = Standing((frame + 1) % 6);
				}
				this.updateSprite();
				cacheTime = currentTime;
			}
		});
	}

	private function onKeyDown(e:KeyboardEvent) {
		if (e.keyCode == Keyboard.W) {
			this.direction.y = -1;
		} else if (e.keyCode == Keyboard.S) {
			this.direction.y = 1;
		} else if (e.keyCode == Keyboard.A) {
			this.direction.x = -1;
		} else if (e.keyCode == Keyboard.D) {
			this.direction.x = 1;
		}
	}

	private function onKeyUp(e:KeyboardEvent) {
		if (e.keyCode == Keyboard.W) {
			this.direction.y = 0;
		} else if (e.keyCode == Keyboard.S) {
			this.direction.y = 0;
		} else if (e.keyCode == Keyboard.A) {
			this.direction.x = 0;
		} else if (e.keyCode == Keyboard.D) {
			this.direction.x = 0;
		}
	}

	private function updateSprite() {
		var index = 0;
		switch (this.state) {
			case Standing(frame):
				index = frame;
			case Digging(frame):
				index = frame + 2;
		}

		var x = (index % 3) * Width;
		var y = Math.round(index / 3) * Height;
		this.sprite.copyPixels(this.spriteSheet, new Rectangle(x, y, x + Width, y + height), new Point(0, 0));
	}
}
