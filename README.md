# 🐼 Panda Nap

A delightful iOS puzzle game where you help a sleepy panda reach her bed by removing obstacles. Be careful not to wake her up!

[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![SpriteKit](https://img.shields.io/badge/SpriteKit-Game%20Engine-green.svg)](https://developer.apple.com/spritekit/)
[![App Store](https://img.shields.io/badge/App%20Store-Download-blue.svg)](https://apps.apple.com/us/app/panda-nap-panda-games/id1519636895)

## 📱 Download

**Available on the App Store**: [Download Panda Nap](https://apps.apple.com/us/app/panda-nap-panda-games/id1519636895)

## 🖼️ Screenshots

<div align="center">
  <img src="images/1.png" width="300" alt="Panda Nap Screenshot 1">
  <img src="images/2.png" width="300" alt="Panda Nap Screenshot 2">
  <img src="images/3.png" width="300" alt="Panda Nap Screenshot 3">
</div>

## 🎮 Game Description

The panda is taking a nap, don't wake her up! In this physics-based puzzle game, you need to strategically remove obstacles so that the panda can fall smoothly onto her bed. The challenge is to ensure the panda doesn't fall to the ground, as that would wake her up and end the level.

### Key Features
- **13 Challenging Levels**: Includes three new remix challenges
- **Physics-Based Gameplay**: Realistic physics simulation using SpriteKit
- **Intuitive Touch Controls**: Simple tap-to-remove obstacle mechanics
- **Progressive Difficulty**: Levels become more challenging as you advance
- **Beautiful Artwork**: Charming panda character and relaxing visual design
- **Adjustable Feedback**: Separate controls for music, sound effects, and haptics
- **Quick Continue**: Open the highest unlocked level directly from the map
- **Clear Progress**: Completion counter, checkmarks, and lock icons on the level map
- **Help Anytime**: Revisit the controls and rules through Settings → How to Play
- **Multi-language Support**: Available in English and Chinese (Simplified & Traditional)

## 🎯 How to Play

1. **Objective**: Help the panda reach her bed safely
2. **Controls**: Tap on obstacles to remove them
3. **Challenge**: The panda must not fall to the ground (she'll wake up!)
4. **Success**: Guide the panda to land gently on the bed
5. **Progression**: Complete each level to unlock the next one
6. **Results**: Choose Retry or Levels after a loss, and Next Level after a win

The first level highlights a removable block until you make your first move. Open **Settings** from the level map or a level to adjust music, sound effects, and haptics.

Choose **Continue: Level N** on the map to start the highest unlocked puzzle. After completing all 13 levels, **Replay Levels** scrolls the map back to the first level so you can choose a favorite. Settings → **How to Play** explains the rules without resetting your tutorial or progress; gameplay stays paused until you close Settings.

## 🛠 Technical Details

### Built With
- **SpriteKit**: Apple's 2D game framework for physics and rendering
- **Swift**: Modern iOS development language
- **Swift Package Manager**: Dependency management in the Xcode project
- **Google Mobile Ads**: Monetization through banner and interstitial ads

### Dependencies
- `GoogleMobileAds` 13.10.0 (Swift Package Manager): Banner and interstitial ads

Localization, Auto Layout, menu scrolling, and view configuration now use first-party APIs.

### Architecture
- **MVC Pattern**: Model-View-Controller architecture
- **SpriteKit Scenes**: Separate scenes for menu and gameplay
- **Physics Engine**: Realistic collision detection and physics simulation
- **Audio Management**: Background music and sound effect handling

## 📱 Requirements

- **iOS**: 13.0 or later
- **Devices**: iPhone and iPad (Universal app)
- **Mac**: macOS 10.15 or later through Mac Catalyst, with Intel and Apple silicon support
- **Orientation**: Landscape mode only
- **Xcode**: 16.0 or later (for development)

## 🚀 Installation & Setup

### Prerequisites
- Xcode 16.0 or later
- iOS 13.0+ deployment target

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/banghuazhao/panda-nap.git
   cd panda-nap
   ```

2. **Open the project**
   ```bash
   open "Panda Nap.xcodeproj"
   ```
   Xcode resolves Google Mobile Ads automatically through Swift Package Manager.

3. **Configure Ad IDs** (for distribution)
   - Debug and local Release builds use Google's test ad IDs.
   - Add your app ID and ad unit IDs to the ignored `Panda Nap/Config/Release.xcconfig` for App Store builds. `Production.xcconfig` includes that local file when present.
   - Review the `SKAdNetworkItems` in `Info.plist` whenever Google updates its [privacy strategy](https://developers.google.com/admob/ios/privacy/strategies).

4. **Build and run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Progress regression check

Run this from the repository root to check fresh installs, older saves, invalid values, and final-level completion:

```bash
swiftc 'Panda Nap/Model/LevelProgress.swift' Scripts/validate-level-progress.swift -o /tmp/panda-progress-check
/tmp/panda-progress-check
```

## 📁 Project Structure

```
Panda Nap/
├── Controller/           # View controllers
├── Model/               # Game objects and physics bodies
├── Scene/               # SpriteKit scenes and level files
├── Sound/               # Audio assets
├── Tools/               # Utilities and extensions
├── View/                # Custom UI components
├── Assets.xcassets/     # Images and app icons
└── Localization/        # Multi-language support
```

### Key Components

- **GameScene.swift**: Main gameplay logic and physics
- **PandaNode.swift**: Panda character behavior and animations
- **BedNode.swift**: Bed object and win condition
- **BlockNode.swift**: Removable obstacle objects
- **MenuScene.swift**: Main menu and level selection
- **Constants.swift**: Game configuration and constants

## 🎨 Assets & Resources

### Game Assets
- **Panda Character**: Multiple states (normal, scared, sleeping)
- **Obstacles**: Various block types and configurations
- **Background**: Relaxing visual design
- **UI Elements**: Menu templates and buttons

### Audio
- **Background Music**: Relaxing ambient soundtrack
- **Sound Effects**: Victory, lose, and interaction sounds

## 🌍 Localization

The game supports multiple languages:
- **English** (`en.lproj`)
- **Chinese Simplified** (`zh-Hans.lproj`)
- **Chinese Traditional** (`zh-Hant.lproj`)

## 📊 Monetization

Ads and their consent SDKs are included only in the iOS build. The Mac Catalyst build has no ads or tracking prompts.

- **Banner Ads**: Displayed during gameplay
- **Interstitial Ads**: Shown after losing multiple times
- **App Store Integration**: Links to other apps by the developer

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Tree vector**: Created by brgfx - [www.freepik.com](https://www.freepik.com/free-photos-vectors/tree)
- **Animal vector**: Created by brgfx - [www.freepik.com](https://www.freepik.com/free-photos-vectors/animal)

## 👨‍💻 Developer

**Banghua Zhao**

- **GitHub**: [@banghuazhao](https://github.com/banghuazhao)
- **Website**: [Personal Website](https://banghuazhao.github.io/)
- **LinkedIn**: [LinkedIn Profile](https://linkedin.com/in/banghuazhao)
- **YouTube**: [NewIsleJourneys](https://youtube.com/@NewIsleJourneys)

---

⭐ If you enjoy this game, please give it a star on GitHub! 
