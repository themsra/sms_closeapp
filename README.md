# SMS Backup / Phone Link foundation

This build keeps the original SMS features and adds the foundation for a user-authorized gallery/file manager and Telegram file transfer.

## Added
- `FileItem` and `FolderItem` models
- MediaStore-backed gallery service through `photo_manager`
- User-selected document/folder access through `file_picker`
- Telegram document upload service
- Telegram polling skeleton with a separate command/authorization layer
- Storage screen reachable from the main app

## Important
The Telegram command router is intentionally not wired to arbitrary filesystem access yet. The next step is to implement strict Telegram user/chat authorization and then map commands to the files the user has explicitly granted access to.

After extracting:

```bash
flutter pub get
flutter run
```

## Telegram gallery control

After saving Bot Token and Chat ID in the app, keep the app running and use the bot:

- `/start` — shows the control menu.
- `🖼 گالری` — lists gallery folders/albums.
- Tap a folder — lists its media files.
- Tap a file — sends that file to the configured Chat ID.
- `⬅️` buttons navigate back.

The bot only responds to the configured Chat ID. General non-media files are intentionally left for a separate Android Storage Access Framework step because modern Android does not grant unrestricted filesystem access to ordinary apps.
