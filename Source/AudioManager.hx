package;

import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

// Manager to play sounds and make sure we stay monohponic (one sound channel at
// a time).
class AudioManager {
  private final ohNo:Sound;
  private final backgroundMusic:Sound;

  private var backgroundMusicChannel:SoundChannel;
  private var isNonMusicSoundPlaying = false;

  public function new() {
    backgroundMusic = Assets.getSound("Assets/k2lu.mp3");
    ohNo = Assets.getSound("Assets/oh_no.mp3");
    resumeBackgroundMusic();
  }

  public function playOhNo() {
    playOneOffSound(ohNo, 1000);
  }

  private function playOneOffSound(s:Sound, timeMS:Int) {
    if (isNonMusicSoundPlaying) {
      return;
    }
    isNonMusicSoundPlaying = true;

    backgroundMusicChannel.stop();
    s.play(0, 1);
    markCurrentSoundCompleteAfter(timeMS);
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
  }
}
