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
import haxe.ds.ReadOnlyArray;

enum State {
  Title(frame:Int);
  InGame(frame:Int);
  DayInfo(frame:Int);
  GameOver(frame:Int);
  Transition(frame:Int, current:State, next:State);
}

class Main extends Sprite {
  public var state:State;

  public static inline var WhiteColor = 0xc7f0d8;
  public static inline var BlackColor = 0x43523d;

  // Day lengths in seconds
  public static var DayLengths:ReadOnlyArray<Int> = [80, 60, 60, 50, 50, 40, 40, 40, 40, 40, 30, 30, 30];

  // Milliseconds in a frame
  public static inline var FrameTime = 200;

  public var game:Game;
  public var dayTransition:DayTransition;
  public var title:Sky;
  public var transition:Transition;
  public var gameEnd:GameEnd;

  var audioManager:AudioManager;

  public function new() {
    super();

    audioManager = new AudioManager();

    this.shader = new NokiaShader();
    this.game = new Game(audioManager, function() {
      switch this.state {
        case InGame(frame):
          return true;
        default:
          return false;
      }
    });
    addChild(game);
    this.game.init();
    this.dayTransition = new DayTransition(0, 0, 0, 0);
    addChild(dayTransition);
    this.transition = new Transition(0x43523d);
    addChild(transition);
    this.title = new Sky();
    addChild(title);

    this.gameEnd = new GameEnd(false, audioManager);
    addChild(gameEnd);

    this.state = Title(0);

    var cacheTime = getTimer();
    this.addEventListener(Event.ENTER_FRAME, function(e) {
      var currentTime = getTimer();
      var deltaTime = currentTime - cacheTime;
      if (deltaTime > FrameTime) {
        this.onFrame();
        cacheTime = currentTime;
      }
    });

    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
  }

  private function onKeyDown(e:KeyboardEvent) {
    switch (this.state) {
      case Title(frame):
        if (e.keyCode == Keyboard.Z && e.ctrlKey && e.shiftKey) {
          this.transition.color = WhiteColor;
          this.gameEnd.won = true;
          this.gameEnd.onFrame(0);
          this.state = Transition(0, DayInfo(frame), GameOver(frame));
        } else if (e.keyCode == Keyboard.X && e.ctrlKey && e.shiftKey) {
          this.transition.color = WhiteColor;
          this.gameEnd.won = false;
          this.gameEnd.onFrame(0);
          this.state = Transition(0, DayInfo(frame), GameOver(frame));
        } else if (e.keyCode == Keyboard.E && frame > 2) {
          trace(DayLengths[this.dayTransition.day], FrameTime, this.dayTransition.day);
          this.game.onBeginDay(Math.round(1000 * DayLengths[this.dayTransition.day] / FrameTime));
          this.transition.color = BlackColor;
          this.state = Transition(0, Title(frame), InGame(0));
        }
      case DayInfo(frame):
        if (e.keyCode == Keyboard.E && frame > 2) {
          if (this.dayTransition.day < 13) {
            this.game.onBeginDay(Math.round(1000 * DayLengths[this.dayTransition.day] / FrameTime));
            this.transition.color = BlackColor;
            this.state = Transition(0, DayInfo(frame), InGame(0));
          } else {
            this.transition.color = WhiteColor;
            this.gameEnd.won = this.dayTransition.money >= 666;
            this.gameEnd.onFrame(0);
            this.state = Transition(0, DayInfo(frame), GameOver(frame));
          }
        }
      case GameOver(frame):
        if (e.keyCode == Keyboard.E && frame > 2) {
          this.transition.color = WhiteColor;
          this.state = Transition(0, GameOver(frame), Title(0));
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
        if (frame > this.game.dayFrames) {
          var dayData = this.game.onDayEnd();
          var gravesFilled = dayData.gravesFilled;
          var ghostsReleased = dayData.ghostsReleased;
          this.dayTransition.update(this.dayTransition.day
            + 1, gravesFilled, ghostsReleased,
            this.dayTransition.money
            + gravesFilled * 5
            + ghostsReleased * 20);
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
      case GameOver(frame):
        this.gameEnd.onFrame(frame);
        this.state = GameOver(frame + 1);
    }
    removeChildren();
    switch (this.state) {
      case Title(frame):
        addChild(this.title);
      case InGame(frame):
        addChild(this.game);
      case DayInfo(frame):
        addChild(this.dayTransition);
      case GameOver(frame):
        addChild(this.gameEnd);
      case Transition(frame, from, to):
        if (frame <= 5) {
          switch (from) {
            case Title(frame):
              addChild(this.title);
            case InGame(frame):
              addChild(this.game);
            case DayInfo(frame):
              addChild(this.dayTransition);
            case GameOver(frame):
              addChild(this.gameEnd);
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
            case GameOver(frame):
              addChild(this.gameEnd);
            default:
              addChild(this.game);
          }
        }
        addChild(this.transition);
    }
  }
}
