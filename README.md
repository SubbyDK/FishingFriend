# FishingFriend

<p align="center">
  <img src="https://img.shields.io/badge/Interface-3.3.5a-blue.svg" alt="Interface">
  <img src="https://img.shields.io/badge/Version-0.0.1-green.svg" alt="Version">
  <img src="https://img.shields.io/badge/Author-Subby-orange.svg" alt="Author">
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
2. Copy the `FishingFriend` folder into your `Interface\AddOns` directory.
3. Ensure the structure looks like this:
```
Interface/
└── AddOns/
    └── FishingFriend/
        ├── Sounds/
        │   └── GoodFishing.ogg
        ├── FishingFriend.toc
        ├── FishingFriend.lua
        ├── FishingFriendUI.lua
        └── FishingFriendOpen.lua
```
4. Restart World of Warcraft.

### 🗑️ Uninstallation

1. Delete the `FishingFriend` folder from your `Interface\AddOns` directory.
2. (Optional) To completely remove all saved statistics and settings, delete the following files from your `WTF` folder:
```
WTF/
└── Account/
    └── {ACCOUNT_NAME}/
        ├── SavedVariables/
        │   └── FishingFriend.lua
        └── {SERVER_NAME}/
            └── {CHARACTER_NAME}/
                └── SavedVariables/
                    └── FishingFriend.lua
```
---

### 🌍 Localization
The addon automatically detects your client language and supports localization for:  
English, German, French, Spanish, Russian, Chinese, Korean, Italian, and Portuguese.

---

### ⚠️ Caution
This version is specifically made for **Project Ascension - Bronzebeard**.  
For various reasons, they have changed the IDs for many items, which can affect the "Open!" button functionality.  
If it is not working as intended, please disable the button in the menu.  
All other features should work as expected.

---

### 👤 Author
**Created by Subby**  
*Tight lines and happy fishing!*

---

## 📄 License

MIT License — do what you want with it. Credits appreciated but not required.
