package;

import Game.EndOfDayData;
import Shaders.NokiaShader;
import Transition.Transition;
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
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

enum State {
  Title(frame:Int);
  InGame(frame:Int);
  DayInfo(frame:Int);
  Transition(frame:Int, current:State, next:State);
}

class Main extends Sprite {
  public var state:State;

  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  public var game:Game;
  public var dayTransition:DayTransition;
  public var title:Sky;
  public var transition:Transition;

  public function new() {
    super();

    this.shader = new NokiaShader();
    this.game = new Game(function() {
      switch this.state {
        case InGame(frame):
          return true;
        default:
          return false;
      }
    });
    addChild(game);
    this.game.init();
    this.dayTransition = new DayTransition(0, 0, 0);
    addChild(dayTransition);
    this.transition = new Transition(0x43523d);
    addChild(transition);
    this.title = new Sky();
    addChild(title);

    this.state = Title(0);

    var cacheTime = getTimer();
    this.addEventListener(Event.ENTER_FRAME, function(e) {
      var currentTime = getTimer();
      var deltaTime = currentTime - cacheTime;
      if (deltaTime > 200) {
        this.onFrame();
        cacheTime = currentTime;
      }
    });

    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
  }

  private function onKeyDown(e:KeyboardEvent) {
    switch (this.state) {
      case Title(frame):
        if (e.keyCode == Keyboard.E && frame > 2) {
          this.game.onBeginDay();
          this.transition.color = BlackColor;
          this.state = Transition(0, Title(frame), InGame(0));
        }
      case DayInfo(frame):
        if (e.keyCode == Keyboard.E && frame > 2) {
          this.game.onBeginDay();
          this.transition.color = BlackColor;
          this.state = Transition(0, DayInfo(frame), InGame(0));
        }
      default:
        return;
    }
  }

  public function onFrame() {
    switch (this.state) {
      case Title(frame):
        this.title.onFrame(frame);
        this.state = Title(frame + 1);
      case InGame(frame):
        if (frame > Game.DayFrames) {
          var dayData = this.game.onDayEnd();
          var nGraves = dayData.gravesFilled;
          this.dayTransition.update(this.dayTransition.day + 1, nGraves, this.dayTransition.money + nGraves * 10);
          this.transition.color = WhiteColor;
          this.state = Transition(0, InGame(0), DayInfo(0));
        } else {
          this.game.onFrame(frame);
          this.state = InGame(frame + 1);
        }
      case DayInfo(frame):
        this.dayTransition.onFrame();
        this.state = DayInfo(frame + 1);
      case Transition(frame, from, to):
        this.transition.onFrame(frame);
        if (frame > 8) {
          this.state = to;
        } else {
          this.state = Transition(frame + 1, from, to);
        }
    }
    removeChildren();
    switch (this.state) {
      case Title(frame):
        addChild(this.title);
      case InGame(frame):
        addChild(this.game);
      case DayInfo(frame):
        addChild(this.dayTransition);
      case Transition(frame, from, to):
        if (frame <= 5) {
          switch (from) {
            case Title(frame):
              addChild(this.title);
            case InGame(frame):
              addChild(this.game);
            case DayInfo(frame):
              addChild(this.dayTransition);
            default:
              addChild(this.game);
          }
        } else {
          switch (to) {
            case Title(frame):
              addChild(this.title);
            case InGame(frame):
              addChild(this.game);
            case DayInfo(frame):
              addChild(this.dayTransition);
            default:
              addChild(this.game);
          }
        }
        addChild(this.transition);
    }
  }
}
