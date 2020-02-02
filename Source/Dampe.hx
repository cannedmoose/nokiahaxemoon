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

// Spritesheet is 3x4 with 10 filled slots
// standing/walking slots with shovel raised/lowered
// 0 - standing
// 1 - walking
// 2 - standing
// 3 - walking
// 4:10 - digging

enum State {
	Standing(frame:Int);
	Walking(frame:Int);
	Digging(frame:Int);
}

class Dampe extends Sprite {
	public static inline var Width = 13;
	public static inline var Height = 12;

	var state:State;
	var spriteSheet:BitmapData;
	var sprite:Bitmap;
	var direction:Point;
	var flip = false;
	var digCallback:Point->Void;

	public function new(digCallback:Point->Void) {
		super();

		this.state = Standing(0);
		this.spriteSheet = Assets.getBitmapData("Assets/dampe_alt.png");
		this.sprite = new Bitmap(new BitmapData(Width, Height, true, 0xFFFFFFFF));
		this.direction = new Point(0, 0);
		this.digCallback = digCallback;
		addChild(this.sprite);
		this.updateSprite();
	}

	public function init() {
		var cacheTime = getTimer();
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		this.addEventListener(Event.ENTER_FRAME, function(e) {
			var currentTime = getTimer();
			var deltaTime = currentTime - cacheTime;
			if (deltaTime > 200) {
				this.onFrame();
				cacheTime = currentTime;
			}
		});
	}

	public function onFrame() {
		switch (this.state) {
			case Standing(frame):
				this.state = Standing((frame + 1) % 4);
			case Walking(frame):
				// Actually take a step and reset direction
				if (frame % 2 == 1) {
					this.x += this.direction.x;
					this.y += this.direction.y;
					this.direction.x = 0;
					this.direction.y = 0;
					this.state = Standing((frame + 1) % 4);
				} else {
					// They should move one frame on the second frame of walking
					this.state = Walking((frame + 1) % 4);
				}
			case Digging(frame):
				if (frame == 6) {
					this.state = Standing(0);
				} else {
					if (frame == 2) {
						// Spawn hole
						this.digCallback(new Point(2, 11));
					}
					this.state = Digging((frame + 1) % 7);
				}
		}
		this.updateSprite();
	}

	private function onKeyDown(e:KeyboardEvent) {
		switch (this.state) {
			case Standing(frame):
				if (e.keyCode == Keyboard.W) {
					this.direction.y = -1;
					this.state = Walking(Math.floor(frame / 2) * 2);
				} else if (e.keyCode == Keyboard.S) {
					this.direction.y = 1;
					this.state = Walking(Math.floor(frame / 2) * 2);
				} else if (e.keyCode == Keyboard.A) {
					this.direction.x = -1;
					this.flip = false;
					this.state = Walking(Math.floor(frame / 2) * 2);
				} else if (e.keyCode == Keyboard.D) {
					this.direction.x = 1;
					this.flip = true;
					this.state = Walking(Math.floor(frame / 2) * 2);
				} else if (e.keyCode == Keyboard.E) {
					this.state = Digging(0);
				}
			case Walking(frame):
				if (e.keyCode == Keyboard.W) {
					this.direction.y = -1;
					this.direction.x = 0;
				} else if (e.keyCode == Keyboard.S) {
					this.direction.y = 1;
					this.direction.x = 0;
				} else if (e.keyCode == Keyboard.A) {
					this.direction.x = -1;
					this.direction.y = 0;
					this.flip = false;
				} else if (e.keyCode == Keyboard.D) {
					this.direction.x = 1;
					this.direction.y = 0;
					this.flip = true;
				} else if (e.keyCode == Keyboard.E) {
					this.state = Digging(0);
				}
			case Digging(frame):
				// No-op
				return;
		}
	}

	private function updateSprite() {
		var index = 0;
		switch (this.state) {
			case Standing(frame):
				index = Math.floor(frame / 2) * 2;
			case Walking(frame):
				index = frame;
			case Digging(frame):
				index = frame + 3;
		}
		var x = (index % 3) * Width;

		var y = Math.floor(index / 3) * Height;
		this.sprite.bitmapData.copyPixels(this.spriteSheet, new Rectangle(x, y, x + Width, y + height), new Point(0, 0));
		if (this.flip) {
			this.sprite.x = Width + 2;
			this.sprite.scaleX = -1;
		} else {
			this.sprite.scaleX = 1;
			this.sprite.x = 0;
		}
	}
}
