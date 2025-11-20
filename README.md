# 🧙‍♂️ IconWizard

<img width="256" height="256" alt="icon_icon4" src="https://github.com/user-attachments/assets/3d57a055-2f03-4be5-8608-bc5c3687c4f5" />

✨ *Abracadabra! Your folders just got fabulous* ✨

---

## 🔮 What Is This?

Ever looked at a folder and thought, "This needs a better icon"? Or found the perfect PNG but need it as an ICO file? Maybe you want to extract icons from EXE files?

**IconWizard does all that and more.** 

No complicated setup. No command-line wizardry. Just drag, drop, and watch the magic happen! ✨

### 🎯 Two Tools in One

1. **🖼️ Folder Icon Changer** - Customize any folder with beautiful icons
2. **🔄 Image Converter** - Convert images between formats with ease

---

## ✨ Features

### 🎨 Folder Icon Features
- 🖱️ **Drag & Drop** - Just drop a folder on the app
- 🔍 **Smart Scanning** - Automatically finds icons inside folders
- 🎯 **Right-Click Menu** - Access from anywhere
- 🔄 **Batch Processing** - Handle multiple folders at once
- 📂 **Flexible Input** - Browse, paste paths, or drag-n-drop

### 🔮 Image Conversion Features
- 🎨 **Convert to ICO** - Standard or with rounded corners
- 🖼️ **Extract from ICO** - Get PNG images from icon files
- 💎 **Extract from EXE** - Pull icons from programs
- 🌈 **Multiple Formats** - PNG, JPG, WebP, BMP, GIF, SVG, ICO
- 📦 **Batch Convert** - Process entire folders

### 🧪 Smart Features
- ⚡ **Instant Refresh** - No need to restart Explorer
- 🛡️ **Safe Operation** - Preserves file attributes, avoids conflicts
- 🔍 **Deep Scanning** - Uses 4 different methods to extract icons
- 📝 **Debug Logging** - Full operation logs for troubleshooting
- 🎯 **Auto-Rename** - Prevents file overwrites automatically

---

## 🚀 Getting Started

### Requirements

**Minimum:**
- Windows 7 or later
- Administrator rights (only for context menu installation)

**Optional Tools** (for full functionality):
- [ImageMagick](https://imagemagick.org/script/download.php#windows) - For image conversion
- [ResourceHacker](http://www.angusj.com/resourcehacker/) - For EXE icon extraction
- [IconsExtract](https://www.nirsoft.net/utils/iconsext.html) - Alternative extraction tool

> 💡 **Tip:** Place optional tools in the `resources` folder for portable use!

### 📦 Installation

#### Option 1: Portable Mode (No Installation)
```batch
1. Download IconWizard.exe
2. Double-click to run
3. Start using it immediately! ✨
```

#### Option 2: Full Install (Adds Right-Click Menu)
```batch
1. Right-click IconWizard.exe and run
2. Choose [I] - Install Context Menu
3. Now you can right-click any folder → "IconWizard - Change Icon"
4. Enjoy! ✨
```

---

## ⚡ How to Use

### 💫 Method 1: Quick Mode (Easiest)
```
1. Drag a folder onto IconWizard.exe
2. Pick an icon from the options
3. Done! ✨
```

### 🖱️ Method 2: Right-Click Menu
```
1. Right-click any folder
2. Select "IconWizard - Change Icon"
3. Choose your icon!
```

### 📜 Method 3: Main Menu
```
1. Run IconWizard.exe
2. Choose an option from the menu
3. Follow the prompts
```

---

## 📸 Screenshots

### Main Menu
```
 ========================================================================
                          IconWizard by ridwan47
 ========================================================================

 TIP: Drag a folder onto IconWizard for quick access

 ========================================================================
                          MAIN MENU
 ========================================================================

   --- FOLDER ICON CHANGER ---
   [1]  Browse for a folder
   [2]  Paste folder path manually
   [3]  Process all subfolders

   --- IMAGE CONVERTER ---
   [4]  Conversion Tools
```

---

## 🎪 Use Cases

### 🎮 Game/Software Library Organization
Extract icons from game executables and apply them to folders:
```batch
1. Right-click game folder
2. Choose "IconWizard - Change Icon"
3. Select "Process this folder"
4. Watch it find and apply the best icon! 🎮
```

### 🎨 Design Projects
Convert all your design files to ICO format at once:
```batch
1. Open Image Converter
2. Choose "Convert Entire Folder"
3. Select your image folder
4. Get coffee while it processes ☕
```

### 🏢 Professional Organization
Make your work folders easy to identify visually:
```batch
1. Create custom icons for each project
2. Apply them in batch to all folders
3. Never mix up projects again!
```

---

## 🔧 Configuration

### Skip Patterns
You can customize which files to ignore when scanning:
```batch
set "skipFiles=7z,CRC,SFV,dxweb,cheat,protect,launch,crash"
```

### Resource Path
Tools should be placed in the resources folder:
```batch
set "resourcesPath=%~dp0resources\"
```

---

## 🐛 Troubleshooting

### "ImageMagick Not Found"
**Fix:** Download ImageMagick and place `magick.exe` in the `resources` folder.

### "Could not extract icon from EXE"
**Fix:** The EXE might not have an icon, or it's protected. The tool tries 4 different methods automatically.

### "Access Denied"
**Fix:** Run as administrator. Right-click → "Run as administrator"

### Context Menu Not Showing
**Fix:** Reinstall with admin rights. Choose option [I] from the main menu.

### Icons Not Refreshing
**Fix:** Make sure `FolderIconUpdater.exe` is in the `resources` folder.

---

## 📋 Debug Logs

Having issues? Check the log file:
```
Location: %TEMP%\_folder_icon_debug.log
```

Every operation is logged with timestamps - perfect for troubleshooting!

---

## 🤝 Contributing

Found a bug? Want to add features? Pull requests welcome!

**Ideas for contributors:**
- 🌙 Dark mode interface
- 🌍 Multi-language support
- 🎨 More icon style presets
- 📦 Additional conversion formats
- 🎯 Icon preview feature

---

## 📜 License

MIT License - Free to use, modify, and share!

---

## 🙏 Credits

**Created by:** ridwan47

**Built with:**
- ✨ Google Gemini 2.5 Pro (AI assistance)
- 💻 Batch script magic
- 💪 Determination and coffee

**Special thanks:**
- ImageMagick team
- NirSoft (IconsExtract)
- Angus Johnson (ResourceHacker)
- ramdany7 (FolderIconUpdater)

---

## 📞 Support

Need help? Have questions? Want to share cool icon setups?

- 🐛 [Report Issues](https://github.com/ridwan47/iconwizard/issues)
- 💬 [Discussions](https://github.com/ridwan47/iconwizard/discussions)
- ⭐ Star the repo if you find it useful!

---

## 🎉 Fun Facts

- Over 2,000 lines of batch script code
- Can scan up to 50,000 icon indices in EXE files
- Supports UTF-8 for international file names
- Rounded corners use advanced ImageMagick processing
- Debug logs capture everything (including the weird stuff)

---

<div align="center">

### Made with ✨ and way too many GOTO statements

**[⬆ Back to Top](#-iconwizard)**

</div>
