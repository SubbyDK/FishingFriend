# FishingFriend

<p align="center">
  <img src="https://img.shields.io/badge/Interface-3.3.5a-blue.svg" alt="Interface">
  <img src="https://img.shields.io/badge/Version-0.0.4-green.svg" alt="Version">
  <img src="https://img.shields.io/badge/Author-Subby-orange.svg" alt="Author">
  <img src="https://img.shields.io/github/downloads/SubbyDK/FishingFriend/total" alt="Downloads">
</p>

**FishingFriend** is a lightweight, all-in-one utility for World of Warcraft (3.3.5a) designed to make fishing less of a chore and more of a reward.

---

### 💡 The Background
The motivation behind this addon comes from my love for [FishingBuddy](https://legacy-wow.com/wotlk-addons/fishing-buddy/).  
However, I was never satisfied with how it handled lures, it often failed to apply them correctly because zone requirements were inaccurate in the original addon.  
**FishingFriend** fixes this by "learning" from every sub-zone, ensuring your lures are used correctly based on real-time data.

---

### 🚀 Features

*   **Double Right-Click Cast**: No need for action bar buttons, just double right-click anywhere in the world to cast your line.
*   **Smart Auto-Lure**: Automatically detects your current skill and the zone's requirement, applying the best available lure from your bags if needed.
*   **Dynamic Tracker**: A clean UI showing zone name, skill progress, and a list of your catches with their correct quality colors (Epic, Rare, etc.).
*   **Enhanced Fishing Sounds**: Automatically optimizes game volume (Master/SFX) and mutes music/ambience when your pole is equipped.
*   **Clam & Loot Opener**: Provides a dedicated "Open!" button whenever you have clams, trunks, or bloated fish in your inventory.
*   **Rare Catch Alerts**: Plays a custom sound alert whenever you catch a special item from a list (like a quest fish).

---

### 🛠️ Commands

| Command | Description |
| :--- | :--- |
| `/ff` | Open the configuration menu. |
| `/ffcheck` | (Dev tool) Verifies Item IDs against the server database. |
| `/fffind [Name]` | (Dev tool) Search the game cache for a specific Item ID. |

---

### 📦 Installation

1. Download the repository.
2. Rename the folder `FishingFriend-master` to `FishingFriend`.
3. Move the `FishingFriend` folder into your `Interface\AddOns` directory.
4. Ensure the structure looks like this:
```
Interface/
└── AddOns/
    └── FishingFriend/
        ├── Sounds/
        │   └── GoodFishing.ogg
        ├── FishingFriend.lua
        ├── FishingFriend.toc
        ├── FishingFriendOpen.lua
        └── FishingFriendUI.lua
```
5. Restart World of Warcraft.

### 🗑️ Uninstallation

1. Delete the `FishingFriend` folder from your `Interface\AddOns` directory.
2. (Optional) To completely remove all saved statistics and settings, delete the following files from your `WTF` folder:
```
WTF/
└── Account/
    └── {ACCOUNT_NAME}/
        ├── SavedVariables/
        │   ├── FishingFriend.lua
        │   └──FishingFriend.lua.bak
        └── {SERVER_NAME}/
            └── {CHARACTER_NAME}/
                └── SavedVariables/
                    ├── FishingFriend.lua
                    └──FishingFriend.lua.bak
```
---

### 🌍 Localization
The addon automatically detects your client language and supports localization for:  
English, German, French, Spanish, Russian, Chinese, Korean, Italian, and Portuguese.

---

### ⚠️ Caution
This version has only been tested on **Project Ascension - Bronzebeard**.  
For various reasons, private servers sometimes change the Item IDs, if you experience any issues or incorrect item detections, please let me know.  
The addon should work as intended provided that the Item IDs have not been modified on your server.

---

### 👤 Author
**Created by Subby**  
*Tight lines and happy fishing!*

---

## 📄 License

MIT License — do what you want with it. Credits appreciated but not required.
