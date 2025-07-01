# screen_time

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running the project locally

### Server

To run the server locally, you need to have Go installed.

1.  Navigate to the `server` directory:
    ```bash
    cd server
    ```
2.  Run the server:
    ```bash
    go run main.go serve --http=0.0.0.0:8090
    ```
    The server will be running on `http://localhost:8090`.

### App

To run the app locally and have it point to your local server instance:

1.  Open the `lib/api.dart` file.
2.  Change the `apiUrl` to your local server's address. You will need to use your computer's local network IP address for your mobile device to be able to connect to it.

    ```dart
    // const apiUrl = 'https://screentime-api.prod.appadem.in';
    const apiUrl = 'http://<YOUR_LOCAL_IP>:8090';
    ```
3.  Run the Flutter app:
    ```bash
    flutter run
    ```
