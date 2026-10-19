/*
 * Copyright (c) 2013-2017 Razeware LLC
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import AVFoundation
import UIKit

enum GameSettings {
  private static let musicKey = "game.musicEnabled"
  private static let effectsKey = "game.effectsEnabled"
  private static let hapticsKey = "game.hapticsEnabled"
  private static let tutorialKey = "game.tutorialCompleted"

  static var musicEnabled: Bool {
    get { UserDefaults.standard.object(forKey: musicKey) as? Bool ?? true }
    set {
      UserDefaults.standard.set(newValue, forKey: musicKey)
      if !newValue {
        SKTAudio.sharedInstance().pauseBackgroundMusic()
      }
    }
  }

  static var effectsEnabled: Bool {
    get { UserDefaults.standard.object(forKey: effectsKey) as? Bool ?? true }
    set {
      UserDefaults.standard.set(newValue, forKey: effectsKey)
      if !newValue { SKTAudio.sharedInstance().soundEffectPlayer?.stop() }
    }
  }

  static var musicVolume: Float {
    get { AudioLevels.volume(for: .music) }
    set {
      let volume = AudioLevels.setVolume(newValue, for: .music)
      SKTAudio.sharedInstance().backgroundMusicPlayer?.volume = volume
    }
  }

  static var effectsVolume: Float {
    get { AudioLevels.volume(for: .effects) }
    set {
      let volume = AudioLevels.setVolume(newValue, for: .effects)
      SKTAudio.sharedInstance().soundEffectPlayer?.volume = volume
    }
  }

  static var hapticsEnabled: Bool {
    get { UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true }
    set { UserDefaults.standard.set(newValue, forKey: hapticsKey) }
  }

  static var tutorialCompleted: Bool {
    get { UserDefaults.standard.bool(forKey: tutorialKey) }
    set { UserDefaults.standard.set(newValue, forKey: tutorialKey) }
  }

  static var calmerAnimationsEnabled: Bool {
    get { MotionPreferences.appEnabled() }
    set { MotionPreferences.setAppEnabled(newValue) }
  }

  static var reduceMotionEnabled: Bool {
    MotionPreferences.reduceMotionEnabled(appPreference: calmerAnimationsEnabled,
                                         systemPreference: UIAccessibility.isReduceMotionEnabled)
  }
}

/**
 * Audio player that uses AVFoundation to play looping background music and
 * short sound effects. For when using SKActions just isn't good enough.
 */
public class SKTAudio {
  public var backgroundMusicPlayer: AVAudioPlayer?
  public var soundEffectPlayer: AVAudioPlayer?

  public class func sharedInstance() -> SKTAudio {
    return SKTAudioInstance
  }

  public func playBackgroundMusic(_ filename: String) {
    let url = Bundle.main.url(forResource: filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }

    var error: NSError? = nil
    do {
      backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url!)
    } catch let error1 as NSError {
      error = error1
      backgroundMusicPlayer = nil
    }
    if let player = backgroundMusicPlayer {
      player.numberOfLoops = -1
      player.volume = GameSettings.musicVolume
      player.prepareToPlay()
      if GameSettings.musicEnabled { player.play() }
    } else {
      print("Could not create audio player: \(error!)")
    }
  }

  public func pauseBackgroundMusic() {
    if let player = backgroundMusicPlayer {
      if player.isPlaying {
        player.pause()
      }
    }
  }

  public func resumeBackgroundMusic() {
    if let player = backgroundMusicPlayer {
      player.volume = GameSettings.musicVolume
      if GameSettings.musicEnabled && !player.isPlaying {
        player.play()
      }
    }
  }

  public func playSoundEffect(_ filename: String) {
    guard GameSettings.effectsEnabled else { return }
    let url = Bundle.main.url(forResource: filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }

    var error: NSError? = nil
    do {
      soundEffectPlayer = try AVAudioPlayer(contentsOf: url!)
    } catch let error1 as NSError {
      error = error1
      soundEffectPlayer = nil
    }
    if let player = soundEffectPlayer {
      player.numberOfLoops = 0
      player.volume = GameSettings.effectsVolume
      player.prepareToPlay()
      player.play()
    } else {
      print("Could not create audio player: \(error!)")
    }
  }
}

private let SKTAudioInstance = SKTAudio()
