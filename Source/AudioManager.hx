package;

import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

// Manager to play sounds and make sure we stay monohponic (one sound channel at
// a time).
class AudioManager {
  private final ohNo:Sound;
  private final alert:Sound;
  private final success:Sound;
  private final victory:Sound;
  private final backgroundMusic:Sound;

  private var backgroundMusicChannel:SoundChannel;
  private var isNonMusicSoundPlaying = false;
  private var musicStartTime:Float = 0;

  public function new() {
    backgroundMusic = Assets.getSound("Assets/k2lu.mp3");
    ohNo = Assets.getSound("Assets/oh_no.mp3");
    alert = Assets.getSound("Assets/mg_alert.mp3");
    success = Assets.getSound("Assets/success.mp3");
    victory = Assets.getSound("Assets/victory.mp3");
    resumeBackgroundMusic();
  }

  public function playOhNo() {
    playOneOffSound(ohNo, 1000);
  }

  public function playVictory() {
    backgroundMusicChannel.stop();
    var timer = new haxe.Timer(500);
    timer.run = function() {
      playOneOffSound(victory, -1);
      timer.stop();
    };
  }

  public function playSuccess() {
    playOneOffSound(success, 1000);
  }

  public function playAlert() {
    playOneOffSound(alert, 1000);
  }

  private function playOneOffSound(s:Sound, timeMS:Int) {
    if (isNonMusicSoundPlaying) {
      return;
    }
    isNonMusicSoundPlaying = true;

    musicStartTime = backgroundMusicChannel.position;
    backgroundMusicChannel.stop();
    s.play(0, 1);
    if (timeMS >= 0) {
      markCurrentSoundCompleteAfter(timeMS);
    }
  }

  private function markCurrentSoundCompleteAfter(delayMS:Int) {
    var timer = new haxe.Timer(delayMS);
    timer.run = function() {
      isNonMusicSoundPlaying = false;
      resumeBackgroundMusic();
      timer.stop();
    };
  }

  private function resumeBackgroundMusic() {
    backgroundMusicChannel = backgroundMusic.play(0, 9999, new SoundTransform(0.6));
    backgroundMusicChannel.position = musicStartTime;
  }
}
