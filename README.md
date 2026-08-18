# CoAsia Remote Desktop（內部遠端連線專案）

> 本專案是以開源專案 [RustDesk](https://github.com/rustdesk/rustdesk) 為基礎，由 CoAsia 內部客製化而成的遠端連線工具，用途為公司內部遠端支援 / 遠端桌面控制。
> 原始 RustDesk 專案的完整說明（安裝依賴、原始建置流程、多國語言版本連結等）已搬移保存到 [docs/README-rustdesk-upstream.md](docs/README-rustdesk-upstream.md)，一般開發只需參考本文件即可。

> [!CAUTION]
> 本文件與部分分支的程式碼內含**內部網路資訊**（例如驗證伺服器內網 IP），請勿將此 README 或相關 commit 內容公開到公司以外的地方。詳見〈[已知問題與待辦](#已知問題與待辦)〉。

---

## 目錄

- [專案背景](#專案背景)
- [分支架構總覽](#分支架構總覽)
- [各分支詳細差異](#各分支詳細差異)
- [兩大產品線比較](#兩大產品線比較)
- [客製化重點說明](#客製化重點說明)
- [建置方式](#建置方式)
- [已知問題與待辦](#已知問題與待辦)

---

## 專案背景

公司希望有一套「內部可控」的遠端桌面工具，取代對外部公有服務（RustDesk 官方 rendezvous/relay server、`admin.rustdesk.com` API）的依賴，並依角色拆成兩種安裝檔：

- **被控端（Host / User 版）**：安裝在一般使用者電腦上，等待被遠端連線控制，登入後才會顯示 RustDesk 原本的主畫面。
- **控制端（Controller 版）**：安裝在 IT / 客服人員電腦上，用來輸入對方 ID 並主動發起遠端連線。

所有客製化都是在 `master`（即官方 RustDesk 上游分支，會持續同步官方更新）之上，以一系列 `user-custom*` 分支疊加而成，並未回饋（merge）回 `master`。

## 分支架構總覽

```
master  ── 官方 RustDesk 上游，持續追蹤官方 release，不含任何公司客製化
  │
  └─ feat/initial-custom          客製化起點（已停止推進，狀態「不完整」，可視為廢棄）
       │
       └─ user-custom             第一個可執行版本（實際延續的主線，非 feat/initial-custom 的延伸）
            │
            └─ user-custom-develop        MVP：功能皆可使用，正式導入 CoAsia 品牌／圖示
                 │
                 └─ user-custom-develop-ad         加入帳號登入驗證機制（登入後才能進主畫面）
                      │
                      ├─ user-custom-develop-ad-controller   控制端版：CoAsia_Remote_Controller（狀態：uncertain / 實驗中）
                      │
                      └─ user-custom-develop-ad-modify       被控端版：CoAsia_Remote（★ 目前主力開發分支，更新至 12/1）
```

> 這份樹狀圖是依實際 git 歷史（`git merge-base` / `git log branchA..branchB`）整理出來的，不是單純照分支命名猜測。例如 `user-custom-develop-ad-modify` 是接在 `user-custom-develop-ad` 之後、而不是接在 `user-custom-develop-ad-controller` 之後，兩者是**兄弟分支**，各自代表被控端與控制端兩條產品線。

### 各分支狀態一覽

| 分支 | 對應產品／用途 | 執行檔名稱 | 狀態 |
|---|---|---|---|
| `master` | 官方 RustDesk 原始碼 | `rustdesk` | 上游同步用，不部署 |
| `feat/initial-custom` | 客製化最初試驗 | `rustdesk` | ⚠️ 已停滯（commit 標註「不完整」），建議視為廢棄 |
| `user-custom` | 第一版可執行客製檔 | `rustdesk` | 歷史里程碑，已被下游分支取代 |
| `user-custom-develop` | MVP，品牌置換完成 | `CoAsia_Remote` | 歷史里程碑，已被下游分支取代 |
| `user-custom-develop-ad` | 加入登入驗證 | `CoAsia_Remote` | 兩條產品線的共同基礎，本身不直接部署 |
| `user-custom-develop-ad-controller` | 控制端（IT/客服用） | `CoAsia_Remote_Controller` | 開發中，最後一版 commit 訊息標註「uncertain」，需再驗證 |
| `user-custom-develop-ad-modify` | 被控端（一般使用者用） | `CoAsia_Remote` | ★ 目前最新、最活躍的開發分支（11/24–12/1 多次提交） |

---

## 各分支詳細差異

以下依開發先後順序說明每一階段實際變更的內容（皆已用 `git diff` 逐一核對程式碼，而非只看 commit 訊息）。

### 1. `master` → `feat/initial-custom`

客製化的起點，改動集中在「拿掉官方雲端服務、精簡 UI」：

- **停用官方 API**：`src/common.rs` 將預設 API server 由 `https://admin.rustdesk.com` 改為空字串，不再打官方 API。
- **新增 `key.env`**：內含 `TRUSTED_DEVICES` / `CONFIG_DEVICES` 兩組值。目前在原始碼中**找不到任何地方讀取這個檔案**，推測是預留給日後「預先寫入 server / key」機制用的草稿，尚未串接完成（對應 commit 訊息「1.更改ip/key」）。
- **精簡側邊欄**：`flutter/lib/models/peer_tab_model.dart` 拿掉「Address book（通訊錄）」與「Accessible devices（可存取裝置）」兩個分頁，`maxTabCount` 由 5 降為 3。
- **精簡設定頁**：`flutter/lib/desktop/pages/desktop_setting_page.dart` 拿掉「Account」「About」設定分頁，並隱藏「ID/Relay Server」設定項（使用者無法自行更改連線伺服器）。
- **拿掉公有伺服器導引連結**：`connection_page.dart` 移除「setup_server_tip」提示連結。
- 其餘為版本號、CI workflow、部分語言檔（de/nl）的瑣碎調整。

此分支最後一個 commit（`929594970`，11/18）標註「不完整」，**日期其實晚於下面 `user-custom-develop` 的 MVP 完成日（11/14）**——也就是說這條線後來被放著沒再跟上，實際主線是從 `user-custom` 接下去發展的。

### 2. `feat/initial-custom` → `user-custom`

從 `feat/initial-custom` 的中繼點（「控制端版本」commit）另外接續出來，持續強化連線頁與首頁：

- `connection_page.dart`、`desktop_home_page.dart`、`desktop_tab_page.dart` 陸續調整（版面、狀態邏輯）。
- `key.env` 內容改版一次。
- 新增 `bridge_generated.h`（flutter_rust_bridge 產物，macOS 相關）。

這是第一個被標為「可執行」的版本，共 4 個「可執行檔」commit。

### 3. `user-custom` → `user-custom-develop`

**品牌正式導入**，是目前所有下游分支的品牌基礎：

- `flutter/windows/CMakeLists.txt`：執行檔輸出名稱由 `rustdesk` 改為 **`CoAsia_Remote`**。
- `flutter/windows/runner/Runner.rc`：`FileDescription` / `ProductName` 等 Windows 版本資訊改為 `CoAsia_Remote`。
- 換新的 App 圖示（`res/app_icon.ico`、`res/gen_icon.sh` 支援自動產生各尺寸圖示）。
- `src/lang/tw.rs`：繁體中文字串微調。
- **「11/13 把一次性密碼給加回來」**：在先前精簡設定頁時不小心連帶影響到一次性密碼（OTP）功能，此 commit 把它加回 `desktop_home_page.dart`（+109 行）。
- **「11/14 MVP 功能皆可使用」**：標記為 MVP 完成的里程碑，同時把 `key.env` 從版本控制中移除（改列入 `.gitignore`，成為只存在本機的機密設定檔，不再進 git）。

### 4. `user-custom-develop` → `user-custom-develop-ad`

加入**帳號登入驗證機制**（是否等同「AD／Active Directory 網域驗證」，從程式碼看實際上是**呼叫公司內部一支簡單的帳密驗證 API**，並非真的串接 Windows AD，`ad` 較可能是「帳號 account」的縮寫，建議跟原作者 shawn_tsai 再確認命名意圖）：

- `desktop_home_page.dart` 新增 `LoginPanel`：使用者需輸入帳號密碼、送出後呼叫

  ```
  POST http://10.1.3.99:8000/auth
  ```

  驗證通過（`_loggedIn = true`）才會顯示原本 RustDesk 的主畫面，否則卡在登入畫面。
- 新增 `http` 套件依賴（`flutter/lib/main.dart`）。

> ⚠️ 這支內網 IP（`10.1.3.99:8000`）是寫死在 Dart 程式碼裡的明碼，沒有做 TLS，也沒有 timeout / 錯誤重試機制。若之後要正式上線，建議至少：改成可設定的環境變數、加上 HTTPS、處理逾時與伺服器異常情境。

此分支是後面兩個「產品線」分支的共同基礎，本身不對外發行。

### 5a. `user-custom-develop-ad` → `user-custom-develop-ad-controller`（控制端）

只有 1 個 commit，訊息是「11/19 uncertain」，看起來是還在驗證中的實驗性改動：

- `connection_page.dart`：把原本「只顯示 CoAsia 商標」的畫面，改成顯示「遠端 ID 輸入框 + Peer 清單（最近連線 / 收藏 / 已探索）」，也就是**開放使用者主動輸入對方 ID 發起連線**——這是「控制端」跟「被控端」介面上最核心的差異。
- `Runner.rc` / `CMakeLists.txt`：執行檔品牌改名為 **`CoAsia_Remote_Controller`**。

### 5b. `user-custom-develop-ad` → `user-custom-develop-ad-modify`（被控端，★ 目前主力）

5 個 commit（11/24 ~ 12/1），是目前更新最頻繁、最新的分支，執行檔維持 **`CoAsia_Remote`** 品牌不變：

- `desktop_home_page.dart` 大幅改寫（243 行變動），持續打磨登入後的主畫面。
- `server_page.dart`：改寫「未驗證連入請求」（`buildUnAuthorized`）的處理邏輯——
  - 有人嘗試遠端連線時，強制把視窗帶到前景並取得焦點（`windowManager.show()` / `focus()`），避免使用者沒注意到連線請求跳出視窗。
  - 把「Accept and Elevate（接受並提權）」功能寫死關閉（`canElevate = false`），亦即被控端不再提供以系統管理員權限接受連線的選項。
- `desktop_setting_page.dart`：把先前移除的「ID/Relay Server」設定項改為**用註解方式隱藏**（效果同樣是使用者看不到，但保留程式碼方便之後要恢復時直接取消註解）。
- `src/lang/tw.rs`：繁中字串再微調 1 處。

---

## 兩大產品線比較

| | 控制端<br>`user-custom-develop-ad-controller` | 被控端<br>`user-custom-develop-ad-modify` |
|---|---|---|
| 安裝對象 | IT / 客服人員 | 一般公司同仁 |
| 執行檔名稱 | `CoAsia_Remote_Controller` | `CoAsia_Remote` |
| 登入後畫面 | 遠端 ID 輸入框 + Peer 清單，可**主動發起**連線 | RustDesk 原生「等待被連線」主畫面 |
| 收到連線請求時 | （非此分支重點） | 強制視窗跳到前景，且不提供「提權接受」選項 |
| 目前狀態 | commit 標「uncertain」，需要再驗證 | 持續開發中，進度最新 |

---

## 客製化重點說明

跨分支貫穿的客製化邏輯整理：

1. **拿掉官方雲端依賴**：`admin.rustdesk.com` API 從一開始就被拔掉（見 `feat/initial-custom`），代表本專案預期串接**公司自架的 rendezvous/relay server**，而不是 RustDesk 官方服務。目前程式碼裡看不到自架 server 位址是寫在哪裡設定，建議跟建置流程 / 打包腳本的維護者確認實際 server 位址是怎麼帶進 App 的。
2. **拿掉使用者可自行改連線伺服器的能力**：`ID/Relay Server` 設定、通訊錄、可存取裝置等功能都被移除或隱藏，避免一般使用者亂改設定或看到公司不想曝光的功能。
3. **帳號登入閘門**：`ad` 系列分支之後，App 啟動後必須先登入公司內部帳密系統才能使用，等於是在 RustDesk 之外加了一層公司自己的存取控制。
4. **角色分流**：`ad-controller` 與 `ad-modify` 分別對應「主動連線」與「被動接受連線」兩種使用情境，各自建置成不同執行檔。

## 建置方式

一般 Rust / Flutter 建置指令請參考 [CLAUDE.md](CLAUDE.md)（`python3 build.py --flutter` 等）。針對本專案客製化的部分，建置前請額外注意：

1. **切換到正確的分支**：
   - 要打包「被控端」給一般同仁使用 → `user-custom-develop-ad-modify`
   - 要打包「控制端」給 IT/客服使用 → `user-custom-develop-ad-controller`（目前仍是實驗性版本，建議先測試再發放）
2. **確認 `key.env`**：此檔案自 `user-custom-develop` 之後已被 `.gitignore`，不會出現在 `git clone` 下來的工作目錄中，需要另外向專案負責人索取或依實際需求重建；目前原始碼中尚未找到讀取此檔案的邏輯，使用前建議先確認它是否仍是必要檔案。
3. **內部驗證 API 位址**：`http://10.1.3.99:8000/auth` 目前寫死在 `flutter/lib/desktop/pages/desktop_home_page.dart` 中，跨環境（測試機／正式機）建置前請確認這支 API 是否可連通，或考慮改為可設定值。
4. 執行檔品牌名稱（`CoAsia_Remote` / `CoAsia_Remote_Controller`）由 `flutter/windows/CMakeLists.txt` 與 `flutter/windows/runner/Runner.rc` 控制，兩者需保持一致。

## 已知問題與待辦

- [ ] `key.env`（`TRUSTED_DEVICES` / `CONFIG_DEVICES`）目前查無使用處，需確認是否為未完成功能或已廢棄。
- [ ] 內部驗證 API（`10.1.3.99:8000/auth`）為明碼 HTTP、IP 寫死、無逾時處理，建議正式導入前補強。
- [ ] `feat/initial-custom` 分支已停滯多時，建議確認是否可封存（archive）或刪除，避免後續開發者誤以為是主線。
- [ ] `user-custom-develop-ad-controller` 最後一版 commit 訊息為「uncertain」，功能穩定性需再驗證後才建議發布。
- [ ] 目前沒有分支保護規則、PR 流程或測試涵蓋這些客製化改動，建議之後補上基本的 code review 流程。
- [ ] 本 README 內含內網 IP 等機敏資訊，**請勿外流**；若之後要對外（例如上傳到公開 GitHub）需要先移除相關段落。

---

原始 RustDesk 專案資訊（安裝依賴、原生建置流程、授權、原作者致謝等）請見 [docs/README-rustdesk-upstream.md](docs/README-rustdesk-upstream.md)。
