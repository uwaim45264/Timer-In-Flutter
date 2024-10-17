# TimerApp - Flutter Timer with Notifications, Background Service, and Vibration

## Overview

**TimerApp** is a Flutter application that allows users to set timers with visual feedback, confetti effects, background service execution, local notifications, and vibration on completion. The app is designed with a beautiful UI and supports background execution, so the timer can continue running even when the app is in the background.

### Key Features:
- **Start, Stop, and Pause Timer**: Users can set a timer with hours, minutes, and seconds, and control the timer with start, stop, and pause functions.
- **Local Notifications**: Provides notifications that show the remaining time, with an option to stop the timer directly from the notification.
- **Background Execution**: The timer runs even when the app is minimized or in the background.
- **Confetti Effect**: A confetti animation is triggered when the timer completes.
- **Vibration Feedback**: The device vibrates upon timer completion.
- **Preset Buttons**: Quickly start a 5-minute, 10-minute, or 30-minute timer with preset buttons.
- **Fade and Animation Effects**: Includes fade-in/out animations for the timer display and dynamic color change on the progress indicator.

## Getting Started

### Prerequisites

Before you start, ensure that you have Flutter installed on your machine. You can download Flutter from the official website: [Flutter.dev](https://flutter.dev/docs/get-started/install).

### Packages Used
This app uses several Flutter packages:
- [`confetti`](https://pub.dev/packages/confetti): For confetti animation on timer completion.
- [`flutter_background`](https://pub.dev/packages/flutter_background): To enable the timer to run in the background.
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications): For displaying notifications.
- [`vibration`](https://pub.dev/packages/vibration): For triggering vibration when the timer ends.

To install the dependencies, run:
```bash
flutter pub get
DEVELOPED BY:
SOFTWARE ENGINEER MUHAMMAD UWAIM QURESHI
