# mobile_v2

A Flutter application for controlling and monitoring a trash-collecting robot with AI-powered object detection.

## Features

- **Robot Control**: Remote control of robot movement and operations
- **Real-time Trash Bin Monitoring**: Live tracking of 4-compartment trash bin status (Metal, Paper, Plastic, Other)
- **Detection History**: View past object detection results with images
- **Settings**: Configure robot and app settings
- **Real-time Updates**: Live data sync using Firebase Realtime Database
- **Gamified UI**: Engaging interface with progress indicators and status visualization

## Trash Bin Monitoring

The app includes a dedicated screen to monitor the robot's trash bin with:
- 4 separate compartments for different trash types
- Real-time capacity tracking
- Visual progress indicators
- Overall bin status and statistics
- Reset functionality for bin management

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup

The app uses Firebase for:
- Firestore: Storing detection history
- Realtime Database: Live trash bin status updates
- Cloud Messaging: Push notifications

Make sure to configure your Firebase project and update the configuration files accordingly.
