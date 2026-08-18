# 新機器開發環境設定與編輯指南（被控端 / `user-custom-develop-ad-modify`）

> 本文件說明：在一台全新的電腦上，把這個 repo git clone 下來之後，**怎麼裝環境、怎麼編輯程式碼、怎麼建置出可執行檔**。
> 內容鎖定在目前主力開發分支 **`user-custom-develop-ad-modify`**（被控端 `CoAsia_Remote`）。分支之間的差異與整體架構請先看根目錄的 [README.md](../README.md)。

## 目錄

- [1. 前置需求](#1-前置需求)
- [2. Clone 專案並切換分支](#2-clone-專案並切換分支)
- [3. 安裝相依套件（vcpkg）](#3-安裝相依套件vcpkg)
- [4. 環境變數與內部設定](#4-環境變數與內部設定)
- [5. 建置與執行](#5-建置與執行)
- [6. 怎麼編輯：客製化程式碼在哪裡](#6-怎麼編輯客製化程式碼在哪裡)
- [7. 提交與推送流程](#7-提交與推送流程)
- [8. 常見問題](#8-常見問題)

---

## 1. 前置需求

這是 Windows 上的 Flutter + Rust 專案，新機器需要先裝好：

| 工具 | 用途 | 備註 |
|---|---|---|
| [Rust](https://rustup.rs/) | 核心程式（`src/`、`libs/`）用 | 建議跟現有開發機版本一致，可用 `rustup show` 確認 |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) | 桌面 UI（`flutter/`） | 需啟用 Windows desktop 支援：`flutter config --enable-windows-desktop` |
| [Visual Studio](https://visualstudio.microsoft.com/) + **Desktop development with C++** workload | 編譯 Windows 原生模組必須 | 安裝時勾選「使用 C++ 的傳統型開發」 |
| [vcpkg](https://github.com/microsoft/vcpkg) | C++ 相依套件（libvpx / libyuv / opus / aom） | 見下方第 3 節 |
| Python 3 | 執行 `build.py` 建置腳本 | |
| Git | 版本控制 | |

> Legacy Sciter UI（`src/ui/`）已棄用，本專案兩個產品（被控端／控制端）都是 Flutter 版本，不需要另外下載 Sciter 動態庫。

## 2. Clone 專案並切換分支

```bash
git clone https://github.com/Shawn0604/RustDesk.git
cd RustDesk
git checkout user-custom-develop-ad-modify
```

> `master` 是官方 RustDesk 上游、`user-custom-develop-ad-modify` 才是目前部署給一般同仁使用（被控端）的分支。**不要**在 `master` 上直接開發客製化功能。各分支用途請見 [README.md 的分支架構總覽](../README.md#分支架構總覽)。

## 3. 安裝相依套件（vcpkg）

```bash
git clone https://github.com/microsoft/vcpkg
cd vcpkg
./bootstrap-vcpkg.bat
```

設定環境變數（PowerShell）：

```powershell
$env:VCPKG_ROOT = "C:\path\to\vcpkg"
```

建議把它加進系統環境變數，讓每次開新終端機都自動生效（`系統內容 → 環境變數 → 新增使用者變數 VCPKG_ROOT`）。

安裝 Windows 靜態版套件：

```bash
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static
```

## 4. 環境變數與內部設定

- **`key.env`**：從 `user-custom-develop` 之後這個檔案已被 `.gitignore`，`git clone` 下來的目錄裡**不會有這個檔案**。目前原始碼中查無任何地方讀取它，正常開發（含 build/run）可以先不管；如果之後發現有地方會用到它，請跟專案負責人（shawn_tsai@coasia.com.tw）確認內容再手動建立。
- **內部帳號驗證 API**：登入畫面呼叫的是寫死在程式碼裡的 `http://10.1.3.99:8000/auth`（位置在 [flutter/lib/desktop/pages/desktop_home_page.dart](../flutter/lib/desktop/pages/desktop_home_page.dart)）。在新機器上開發或測試登入功能前，請確認能連到這支內網 API（例如要接 VPN，或這支服務本來就只在辦公室內網開放）。

## 5. 建置與執行

### 開發模式（邊改邊測）

```bash
cd flutter
flutter pub get
flutter run -d windows
```

這會直接啟動 Windows 桌面版，支援 Hot Reload，改 `.dart` 檔存檔後多半可以直接看到畫面更新，適合平常改 UI 用。

### 正式打包執行檔

在專案根目錄執行：

```bash
python3 build.py --flutter
```

> 如需 debug 版本可加 `--flutter` 之外的參數（參考根目錄 [CLAUDE.md](../CLAUDE.md) 的 Build Commands），正式發版建議加 `--release`：
> ```bash
> python3 build.py --flutter --release
> ```

打包完成後的執行檔名稱應該是 **`CoAsia_Remote.exe`**（品牌名稱定義在 [flutter/windows/CMakeLists.txt](../flutter/windows/CMakeLists.txt) 與 [flutter/windows/runner/Runner.rc](../flutter/windows/runner/Runner.rc)，如果打包出來還是 `rustdesk.exe`，代表分支切錯了，請確認是不是在 `user-custom-develop-ad-modify`）。

## 6. 怎麼編輯：客製化程式碼在哪裡

被控端這個分支上，公司客製化的邏輯主要集中在幾個檔案，改東西前建議先看這幾個地方：

| 想改什麼 | 去哪個檔案 |
|---|---|
| 登入畫面 / 登入驗證邏輯 | [flutter/lib/desktop/pages/desktop_home_page.dart](../flutter/lib/desktop/pages/desktop_home_page.dart)（`LoginPanel` / `_LoginPanelState`） |
| 收到遠端連線請求時的行為（跳窗、是否允許提權） | [flutter/lib/desktop/pages/server_page.dart](../flutter/lib/desktop/pages/server_page.dart)（`buildUnAuthorized`） |
| 設定頁要顯示 / 隱藏哪些選項 | [flutter/lib/desktop/pages/desktop_setting_page.dart](../flutter/lib/desktop/pages/desktop_setting_page.dart) |
| 左側分頁（最近連線／收藏／探索）要顯示哪幾個 | [flutter/lib/models/peer_tab_model.dart](../flutter/lib/models/peer_tab_model.dart) |
| 執行檔品牌名稱 / 版本資訊 | [flutter/windows/CMakeLists.txt](../flutter/windows/CMakeLists.txt)、[flutter/windows/runner/Runner.rc](../flutter/windows/runner/Runner.rc) |
| App 圖示 | `res/app_icon.ico`（可用 `res/gen_icon.sh` 重新產生各尺寸） |
| 是否使用官方 RustDesk API server | [src/common.rs](../src/common.rs)（`get_api_server_`） |

其餘泛用的 Rust / Flutter 架構說明（哪個資料夾放什麼、原生模組在哪）請參考根目錄 [CLAUDE.md](../CLAUDE.md) 的「Project Architecture」段落。

## 7. 提交與推送流程

```bash
git add <變更的檔案>
git commit -m "說明這次改了什麼、為什麼改"
git push origin user-custom-develop-ad-modify
```

- 請直接 commit 到 `user-custom-develop-ad-modify`（目前團隊的作法是每個人直接在這條分支上推進度），**不要 push 到 `master`**，那條是保留給官方上游同步用的。
- 如果要嘗試「控制端」相關功能，切換到 `user-custom-develop-ad-controller` 分支操作，不要跟被控端的改動混在一起 commit。

## 8. 常見問題

**Q: `flutter run -d windows` 出現找不到 `windows` device？**
先確認有跑過 `flutter config --enable-windows-desktop`，並且裝了 Visual Studio C++ 開發套件。

**Q: 編譯時找不到 `libvpx` / `libyuv` / `opus` / `aom`？**
確認 `VCPKG_ROOT` 環境變數有正確指到 vcpkg 目錄，且第 3 節的套件都已安裝（`vcpkg list` 可以確認已裝清單）。

**Q: 打包出來的執行檔名字是 `rustdesk.exe` 不是 `CoAsia_Remote.exe`？**
代表目前分支不是 `user-custom-develop-ad-modify`，用 `git branch --show-current` 確認一下。

**Q: 登入畫面一直失敗？**
確認能連到內網 `10.1.3.99:8000`（見第 4 節），不是帳密本身的問題就先排查網路連線。
