# Task 5: push notifications

This folder is the complete, updated result of tasks 2 to 5. Replace the matching folders from task 4 with these ones.

## What players get

| When | Who is notified |
| --- | --- |
| The game starts | everyone |
| It is your turn to give a clue | only that player |
| Voting starts, or a revote after a tie | players who can vote (alive and connected) |
| The spy is caught (Imposter) | only the caught spy, to guess the word |
| The game is over | everyone connected |

Each notification is sent in Arabic and English, replaces the previous notification of the same room, and expires after two minutes. Nothing is sent when a step did not change, so retried calls never notify twice.

## How it works

- The app gives the server this device's OneSignal subscription id (`registerPush`). The ids are stored in `rooms/{id}/private/push`, which no client can read.
- After each game step is committed, the function that made the step sends the notifications through the OneSignal REST API. A failed notification is logged and never breaks the game.
- Targeting uses subscription ids, not external ids, so this feature does not call `OneSignal.login` and does not touch how your other features identify users.
- The ids are deleted together with the room when the last player leaves the lobby.

## Deploy

1. Create a OneSignal REST API key for your app, then store it as a secret and deploy:

```
firebase functions:secrets:set ONESIGNAL_API_KEY
cd spy_game_functions
npm install
npm test
cd ..
firebase deploy --only functions:spygame
```

The deploy asks for `ONESIGNAL_APP_ID` (your OneSignal app id).

2. To run the game without notifications, set `ENABLE_PUSH = false` in `spy_game_functions/src/config.ts` before deploying. No OneSignal values are needed then.

3. In the Flutter app, `onesignal_flutter` (version 5) must be a dependency and `OneSignal.initialize(appId)` must run at startup, as in your other apps. Copy `app/lib/features/spy_game/` over your copy. The lobby asks for notification permission when a player enters a room.

If your app does not use OneSignal, override `pushRegistrarProvider` with your own `PushRegistrar`.

## Things to check

- The request format follows OneSignal's REST API as I know it: the `Authorization: Key <key>` header used by app API keys, `include_subscription_ids`, `headings`, `contents`, `ttl`, and `collapse_id`. It was not sent to the live service from here. If you use an older REST API key, change `Key` to `Basic` in `notifications.ts`.
- Notifications are not shown or hidden specially while the app is open. OneSignal's default applies, and you can change it in your app's OneSignal setup.
- A notification carries `{type: "spy_game", roomId, event}` as data. Opening the room when a notification is tapped is not wired up.

## Verification

- Server: 90 tests pass. The new ones cover which events each step produces and for whom (for example eliminated or disconnected players get no vote prompt), the OneSignal request body, the sender with a fake network (success, HTTP errors, network errors, duplicates, nobody to notify), and that the API key never appears in an error report (checked by deliberately leaking it).
- Flutter: all 19 files parse with a real Dart grammar. They were not compiled, so run `flutter analyze` first. The OneSignal calls (`requestPermission`, `pushSubscription.id`, `addObserver`) were checked against the SDK source for version 5.7.0.
- The functions were type-checked but not run against the Firebase emulator or the OneSignal service.

## Not done yet

- Disconnect detection with Realtime Database presence, and cleanup of abandoned rooms.
- A larger word list.
- The final security review.
