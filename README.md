Got it! Here's an updated version of the README with the details about UIKit, SwiftUI, and the MVVM-C architecture:

---

# Catodoro - A Cat-Themed Pomodoro App 🐱⏲️

Catodoro is a Pomodoro timer app with a twist — it's all about cats! The app helps you stay focused and productive while adding some feline fun to your work or study sessions. Whether you're working, studying, or just trying to stay on track, Catodoro helps you manage your time with Pomodoro intervals, cat-inspired sounds, and a cute interface.

## Features 🐾
- **Pomodoro Timer**: Classic 25-minute work sessions with 5-minute breaks in between. Every 4th cycle has a longer 15-minute break.
- **Cat Sounds**: Enjoy relaxing cat-themed sounds to accompany your work and break sessions.
- **Cute Interface**: Features cat-themed design elements to make working more fun.
- **Customizable Timer**: Adjust the work and break durations to fit your needs.
- **Progress Tracking**: Track how many Pomodoro sessions you've completed throughout the day.
- **Interactive Cat Animation**: Watch your cat grow and change as you complete more Pomodoro sessions!

## Architecture 🏗️

Catodoro is built using **MVVM-C** architecture, combining **UIKit** and **SwiftUI** to create a dynamic and responsive user interface. This allows for flexibility, scalability, and ease of maintenance. Here's a breakdown of the architecture:

- **Model**: Represents the data and logic of the app, including the timer logic and tracking user progress.
- **View**: Built with **UIKit** and **SwiftUI**, ensuring the UI is both functional and beautiful. The cat animations and sounds are integrated to provide an engaging user experience.
- **ViewModel**: Manages the app's business logic, updating the view based on the user's actions and app state.
- **Coordinator**: Handles navigation and flow control between different parts of the app, ensuring a smooth and cohesive user experience.

## Installation 📲

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/yourusername/catodoro.git
   ```

2. Open the project in Xcode.

3. Build and run the app on your desired simulator or physical device.

## Usage 🐾

- Launch the app and select your desired Pomodoro timer duration.
- Start working, and your timer will begin.
- Take a break when your timer signals you to do so. Enjoy the cat-themed sounds during your breaks!
- Keep track of your progress and watch your virtual cat grow the more you work.

## Requirements ⚙️
- iOS 14.0+
- Xcode 12+
- Swift 5.0+
- UIKit
- SwiftUI

## Contributing 🤝
We welcome contributions! Feel free to fork the repository, submit issues, and create pull requests.

### Steps to contribute:
1. Fork the repository.
2. Create a feature branch.
3. Make your changes and commit them.
4. Push your changes to your forked repository.
5. Open a pull request with a description of the changes you've made.

## License 📄
Catodoro is open-source software released under the MIT license.

---

This README highlights the use of **UIKit** and **SwiftUI** for the UI, and emphasizes the **MVVM-C** architecture. Let me know if you'd like to further refine it!
