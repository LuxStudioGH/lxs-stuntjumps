# 🏁 LuxStudio Stunt Jumps

A high-performance, modular stunt jump system for FiveM

This script brings the classic GTA stunt jump experience to your FiveM server with a competitive side!. Players can find stunt jumps, compete for the fastest times and highest air, and climb the global leaderboards.

[Stunt Jump Example](https://youtu.be/JLnn0gu1rXA)
[Stunt Jump Creator Example](https://youtu.be/9NlGzwdTIOg)

---

## ✨ Features

* **Leaderboards:** Real-time tracking of the best times and heights for every single jump.
* **Stunt Editor:** Edit/delete any jump location in-game, as well as create new stunts! 👀
* **Stunt Camera:** Cinematic camera angles that activate automatically when you catch air.
* **Reward System:** Rewards for players who complete a stunt for the first time.
* **Optimized Performance:** Optimized performance to not turn your server into a potato!

---

## 📋 Dependencies

Ensure you have the following installed:

- **qbx_core** (or qb-core)
- **ox_lib**
- **oxmysql**

---

## 🔨 Database

The script is designed to initialize the table automatically on start. However, you can manually run the following SQL if needed:

```sql
CREATE TABLE IF NOT EXISTS `stunt_jumps` (
    `jump_id` VARCHAR(100) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `first_done` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `best_time` FLOAT DEFAULT 999.99,
    `best_height` FLOAT DEFAULT 0.0,
    PRIMARY KEY (`jump_id`, `citizenid`)
);
```

### 🎮 Commands

| Command | Description |
| :--- | :--- |
| `/stuntleaderboard` | Opens the context menu for the stunt jump closest to you |
| `/stuntcreator` | Opens the context menu for editing/deleting/creating stunt jumps! |

---

### 🛡️ Support

If you need any assistance, have questions, or want to report a bug, feel free to join our community:
- https://discord.gg/ZHwpYBXUPZ


--- 

### 🤝 Credits
Original Project - https://forum.cfx.re/t/stunt-jumps-lua/801339

English, German & UwU Translations - [Asraye](https://github.com/AsrayeDev)
Spanish Translations - [World170](https://github.com/World170)
