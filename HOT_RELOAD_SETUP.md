# 🚀 Hot Reload Development Setup for GradeBridge

## **Option 1: Using VS Code Built-in Hot Reload (RECOMMENDED)**

### Step 1: Install Required Extensions
Go to Extensions (Ctrl+Shift+X) and install:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)

### Step 2: Run Flutter with Hot Reload

**Method A - Using Command Palette (Easiest)**
1. Press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)
2. Type: `Flutter: Start Debugging`
3. Press Enter
4. Select your device (emulator or physical device)
5. App will run in debug mode with Hot Reload enabled

**Method B - Using Keyboard Shortcut**
1. Once app is running, Press `R` to **Hot Reload** (fast)
2. Press `Shift+R` for **Hot Restart** (full restart)

### Step 3: Configure VS Code for Auto-Reload
Edit `.vscode/settings.json` (create if doesn't exist):

```json
{
  "dart.flutterAdditionalArgs": ["--verbose"],
  "dart.previewFlutterUiGuides": true,
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

---

## **Option 2: Using Flutter Tasks**

### Step 1: Create `.vscode/tasks.json`

Create a new file `.vscode/tasks.json` in your project root:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Flutter: Run Debug",
      "type": "shell",
      "command": "flutter",
      "args": ["run", "-v"],
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "isBackground": true
    },
    {
      "label": "Flutter: Hot Reload",
      "type": "shell",
      "command": "flutter",
      "args": ["run", "--hot"],
      "problemMatcher": [],
      "dependsOn": "Flutter: Run Debug"
    }
  ]
}
```

### Step 2: Run Using Task
1. Press `Ctrl+Shift+B` (Build task)
2. Select "Flutter: Run Debug"
3. App will start in debug mode

---

## **Option 3: Using Launch Configuration**

### Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "preLaunchTask": "Flutter: Run Debug",
      "args": []
    }
  ]
}
```

---

## **How Hot Reload Works**

### **Hot Reload (Press `R`)**
- ✅ Updates UI code instantly
- ✅ Preserves app state
- ✅ Takes ~1-2 seconds
- ❌ Doesn't reset data
- **Use for:** UI changes, styling, layout updates

### **Hot Restart (Press `Shift+R`)**
- ✅ Full app restart
- ✅ Resets all state
- ✅ Takes ~3-5 seconds
- ✅ Reinitializes data
- **Use for:** Logic changes, data model updates, navigation changes

---

## **Pro Tips for Maximum Efficiency**

1. **Code Formatting**
   - Press `Shift+Alt+F` to auto-format code
   - Saves time on styling issues

2. **Hot Reload Limitations**
   - ❌ Can't change main.dart global changes
   - ❌ Can't change widget constructors
   - ❌ Can't change function signatures
   - → Use **Hot Restart** in these cases

3. **Don't Need to Stop & Start**
   - Keep the app running
   - Just save your file (Ctrl+S)
   - Hot Reload will trigger automatically (if enabled)

4. **Enable Auto-Reload on Save**
   Add to `.vscode/settings.json`:
   ```json
   {
     "dart.hotReloadOnSave": true,
     "editor.formatOnSave": true
   }
   ```

5. **Keyboard Shortcuts Summary**
   - `Ctrl+S` → Save file
   - `R` → Hot Reload (while app running)
   - `Shift+R` → Hot Restart
   - `Ctrl+C` → Stop app
   - `Ctrl+Shift+P` → Command Palette

---

## **Quick Start (Copy-Paste Solution)**

1. Run this command in terminal:
   ```bash
   flutter run
   ```

2. Once app is running:
   - Edit your Dart code
   - Save file (Ctrl+S)
   - Press `R` in terminal
   - Changes appear instantly! ✨

---

## **Troubleshooting**

| Problem | Solution |
|---------|----------|
| Hot Reload not working | Use `Shift+R` (Hot Restart) instead |
| App crashes on Hot Reload | Use `Shift+R` to fully restart |
| Changes not appearing | Make sure file is saved (Ctrl+S) |
| Errors after reload | Check the console output |

---

## **💡 Best Development Workflow**

```
1. Run: flutter run
   ↓
2. Edit code in VS Code
   ↓
3. Save: Ctrl+S
   ↓
4. See changes: Press R
   ↓
5. Repeat steps 2-4
```

**No need to restart every time!** 🎉

---

## **Already Installed Extensions Check**

Run in terminal:
```bash
flutter doctor
```

Should show ✓ for:
- Flutter SDK
- Android SDK (for Android)
- Xcode (for iOS if on Mac)
- VS Code

---

**Enjoy fast, productive development!** 🚀
