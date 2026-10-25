# 導入先PCへの移行プラン（v64 → 現行フル構成）— Claude間引き継ぎ版

作成: 2026-09-25 元PC側のClaudeが、`mousemaster`（2026-10-24 までは `mousemaster_92`） の実フォルダと `CLAUDE.md` を読んで作成。
更新: 2026-10-06 即停止「alt+e → stop」とランチャーのアイコン（2.6 節、付録 A15〜A23）を追加。どちらも任意。
更新: 2026-10-07 `mousemaster.properties` を更新（モード跨ぎで移動が止まらなくなる穴を塞いだ [30]）。3.5 に「alt+g が効かない＝NVIDIA G-Assist」と「カーソルが走り続ける」を追加、診断スクリプト A24/A25（任意）を追加。
更新: 2026-10-12 `mousemaster.properties` を更新（[31] Snipaste 連携: z=スニップ開始、もう一度 z=その場に貼る）。3.5 に Snipaste 無しの時の注意を追加。この文書とスクリプト 25 本・properties・カーソル・アイコンは GitHub の `masasj/mousemaster-config` にも置いた（exe は Releases）。
更新: 2026-10-15 exe を Build 95（663a1e1a）に、properties を 95 用（[32]: indicator の position=mouse / fill-opacity / fill-color）に更新。**両方を同時に入れ替えること**。
更新: 2026-10-14 導入先PCの移行報告（2026-10-13、分岐A で完了）を反映: Startup の `.disabled` 禁止、7 章の雛形のハッシュ、`undo-admin-autostart.bat` と `cursors/apply-cursors.ps1` をリポジトリに追加、運び方に GitHub を明記。
**導入先PC側のClaude（同じアカウントなので同じ skill が出る）が、この文書だけを頼りに進められる**ことを目標に書いてある。
元PCと導入先PCの間でファイルを直接やりとりする手段は無い。運ぶのはユーザー。

**ユーザーが導入先PCのClaudeに貼る一文（案）**:
> `C:\Users\<ユーザー名>\Downloads\mousemaster\SETUP.md` を読んで、書いてある順に進めて。判断が要るところだけ聞いて。

（.md をファイルごと運ばない場合は、この文書の全文をチャットに貼ってもよい。付録Aのスクリプトはそこから再現できる。）

---

## 導入先PC側のClaudeへ（最初に読む）

- **役割**: 導入先PCに、元PCの mousemaster 運用環境（2026-09-25 時点）を**1回だけ複製する**。継続開発はしない。
- **やること**: 2章の順に進める。まず「2.0 現状調査」（何も変えない）→「2.1 最小構成」→ 様子見 → 分岐A/B。
- **やらないこと**:
  - `mousemaster.properties` の編集は 3 章の「変えてよいもの／だめなもの」に従う。数値の調整・切替・機能オフはその場でよい。**キーの組み合わせ（コンボ・ガード・remapping・macro）は導入先PCで触らない**。ハーネスが無いので ctrl+c や alt+tab を壊しても気づけない（元PCで6回やった）。直したい点は導入先側 CLAUDE.md の「未着手・保留」に溜め、まとめて元PC側で直す（3.5 節）。
  - セキュリティソフトや実行制限に弾かれたら**回避しない**。止めてユーザーに報告する。
  - 旧v64と新しい exe を**同時に動かさない**（2つのインスタンスがフックを奪い合って両方おかしくなる。元PCで実証済み）。
  - `restart-mousemaster.bat` は使わない（5章）。
- **skill `/mm` について**: 同じアカウントなので導入先PCでも出る。あの skill が言う「ハーネス `run.sh` を回せ」「`sync-src.sh`」「`WATCH-state.json`」は**元PCの話で、導入先PCには存在しない**。従わなくてよい。導入先PCでは 7章の雛形で `CLAUDE.md` を作り、以後はそれを入口にする。
- **終わったら**: 7章の `CLAUDE.md` を導入先のフォルダに作る → 8章の報告テンプレをユーザーに渡す（元PC側の `CLAUDE.md` の TODO #14 を閉じるため）。

## 0. 前提（ユーザー回答、2026-09-25）

| 項目 | 回答 |
|---|---|
| 導入先PC | Win11、元PCと大体同じセットアップ。ただし mousemaster は **v64 のまま**（2025-07-19 頃の構成） |
| 持っていく範囲 | **今の元PCと同じフル構成**（昇格自動起動・スタートメニュー・PowerToys 側の調整まで） |
| 管理者権限 | **不明** → 2.0 で確認して分岐 A/B |
| 今後の運用 | **追いつかせて終わり**（導入先PCでの継続開発・同期の仕組みは不要） |

## 1. 何を運ぶか

### 1a. ファイルとして運ぶもの（テキストでは運べない）

| ファイル | サイズ | sha256 | 備考 |
|---|---|---|---|
| `mousemaster.exe` | 81,881,734 byte | `e4cdb5498d67cae0eb9a06bd83fc71f85fd43a44a37b2a73d2e35e52147a7fbc` | 作者 petoncle/mousemaster の nightly **663a1e1a = Build 95**（2026-10-15 取得。元PCの本番と同一）。単体で動く（Qt DLL は起動時に temp へ展開される）。**properties の 2026-10-15 版と対**: 95 より前の exe はその properties を読めず、逆に 10/12 版以前の properties は 95 で起動しない（[32]） |
| `mousemaster.properties` | 103,128 byte | `5e5b22a42c6069ca749466bba91ede16424080fb0544413fb9d84be38bd2d99c` | 現行の本番設定（2026-10-15 版、Build 95 用）。1,321 行、LF 改行のまま運ぶ（CRLF に直さない）。[31] Snipaste 連携（z で開始、もう一度 z で貼る）入り。Snipaste を入れないなら 3.5 の行を見て [31] の 7 行＋[31b] の 2 行をコメントアウト |
| （任意）`cursors\spinner-arcbloom-red-32.ani`, `cursors\spinner-arcbloom-red-app-32.ani`, `cursors\pick-cursor.bat`, `cursors\remove-spinner-cursors.bat`, `cursors\backup-cursors.reg` | 各 189KB / 2.4KB 等 | — | 待機カーソルの差し替え。見た目だけなので最後、または省略可 |
| （任意）`mm4-start.ico`, `mm4-stop.ico` | 各 369,214 byte | start `0c0ba858926bb52e8258fca4cce74c69e02684249a80fe907a5b07b6d7567f80` / stop `1d444dfb529f4a3ed12796b10f14ded1fe309d62a8c57eb98e8a186e9fd4e8e0` | スタートメニューの「mousemaster」「mousemaster stop」のアイコン対（紫＝起動、赤＝停止。2.6 節）。見た目だけ。無ければマウスのコントロールパネルのアイコンのまま |

運び方: GitHub `masasj/mousemaster-config`（Code → Download ZIP でこの文書・properties・スクリプト、Releases で exe。exe が無ければ petoncle/mousemaster の nightly を落としてハッシュで照合、2026-10-13 の導入先PCはそうした）。ほかは USB など。
**導入先PCに置いたら必ずハッシュを照合する**（PowerShell、管理者権限不要）:

```powershell
Get-FileHash -Algorithm SHA256 .\mousemaster.exe, .\mousemaster.properties | Format-List Path, Hash
```

上の表と一致しなければ運搬で壊れている。使わない。

### 1b. この文書から再現するもの（付録A、テキスト）

導入先のフォルダに置く運用スクリプト 25 本（A1〜A14 の 14 本＋2.6 節の即停止・アイコン用 A15〜A23 の 9 本＋診断用 A24〜A25 の 2 本。後の 11 本は任意）。全文を付録Aに載せた。**元PCと同じ内容にすること**（1年分の踏み抜きが反映されている）。

保存規則（元PC側の不変条件）:
- `.bat` / `.ps1` は **ASCII のみ・CRLF 改行**。日本語Windowsの cmd は UTF-8 や LF だと `for`/`if` ブロックや `^` 継続行の解析が壊れて黙って落ちる。付録Aのスクリプトはすべて英語コメントなので ASCII で問題ない。
- ファイル名は付録Aの見出しどおり（他のスクリプトが相対名で呼び合っている）。
- `.bat` の `echo` 行に裸の `>` を書かない（リダイレクトになって対象ファイルを空にする。実害あり）。

### 1c. 運ばないもの（理由つき）

| 対象 | 理由 |
|---|---|
| `effects-pr/` `docs-pr/` `icon/`、`mousemaster_test_harness`、`.git`、ソース一式 | 導入先PCでは開発しない。ハーネスは 3.5 節の運用（コンボ変更は元PC側で）なら不要。コンボ変更が多くなったら別途持ち込む |
| `mousemaster.properties.bak-*`（40件超）、`test-*.properties`、`LOG.md`、元PCの `CLAUDE.md`、`WATCH-state.json`、写真 | デバッグ史・私物。導入先PCに置く理由がない |
| `fix-other-tasks.bat/.ps1` | 元PCにだけあった旧タスク（`mousemaster-fast-autostart` / `mousemaster-resume-start`）の後始末。導入先PCには無いので no-op |
| `fix-start-menu-entry.bat/.ps1` | `add-start-menu-shortcut` と役割が重なる（既存の `mousemaster.lnk` を差し替える版）。新規なら add の方だけでよい |
| `fix-topmost.bat/.ps1`、`check-uiaccess.bat/.ps1`、`swap-nightly.*`、`get-nightly.*`、`switch-build.*` | 元PC側の運用・調査用。必要になったら元PCから取る |
| `claude-to-front.ahk` 一式 | AutoHotkey v2 のインストールが要るので**入れない**。欲しくなったら別判断 |
| **ExplorerPatcher／タスクバー左置き・時計書式などの Windows シェル改造** | mousemaster と無関係。**スコープ外** |

## 2. 導入先PCでの手順

### 2.0 現状調査（何も変えない。全部 PowerShell 読み取りのみ）

**(1) 旧 v64 の居場所と、その自動起動。**
`mousemaster.properties` のヘッダに「由来: `C:\Program Files\mousemaster` (v64)」とあるので、**導入先PCの v64 も `C:\Program Files\mousemaster` にある可能性が高い**。Program Files は管理者でないと書き換えられないので、**そこは触らず放置**し、新しい方を Downloads 側に置いて切り替える。
ただし**旧 v64 が自動起動していたら止める**（二重起動は禁忌）。探す場所:

```powershell
Get-Process mousemaster -ErrorAction SilentlyContinue | Select-Object Id, Path, StartTime
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskName '*mousemaster*' -ErrorAction SilentlyContinue | Select-Object TaskName, State, @{n='RunLevel';e={$_.Principal.RunLevel}}
```

見つかった起動口は「無効化 or **Startup フォルダの外へ移す**（例: 隣に `v64-startup-disabled\` を作ってそこへ）」で止める（消さない。戻せるように）。**Startup の中で `.disabled` にリネームするのは駄目**: Windows はフォルダ内の全ファイルを開こうとするので、サインインのたびに「アプリを選択して .disabled ファイルを開く」が出る（導入先PCで 2026-10-13 に発生）。HKLM 側や Program Files 側は管理者が要るので、無ければユーザーに伝えて止めてもらうか、分岐Bで手動起動に統一して旧 v64 だけ止める。

**(2) 管理者権限。**

```powershell
whoami /groups | findstr /C:"S-1-5-32-544"
```

`BUILTIN\Administrators` の行が出れば UAC で昇格できる（分岐A）。出なければ分岐B。ドメイン参加PCでは出ないことが多い。
（付録Aの `setup-admin-autostart.bat` は自分で UAC を出して昇格するので、行が出ているなら「管理者として実行」を手で選ぶ必要はない。）

**(3) セキュリティソフト。** 止められたら回避せず、その場で止めてユーザーに報告する（不変条件）。

**(4) キーボード配列。** 設定 > 時刻と言語 > 言語と地域 > 日本語 > キーボードレイアウト。`mousemaster.properties` は **jp-kana-jis 前提**（かな・`\`・`ろ` の扱いを含む）。JIS でなければ一部のキーが合わない。ユーザーに聞く。

**(5) 機種。** 元PCはノートPC。「内蔵キーボードで Win キーが死ぬ → Fn+F2」等は**その機種の癖**。導入先PCが別機種なら元PC側の記録を鵜呑みにしない。

### 2.1 最小構成で動作確認（非昇格・自動起動なし）→ 数日様子見

1. 導入先PCに `C:\Users\<導入先のユーザー名>\Downloads\mousemaster` を作る。
   （名前を `mousemaster` に揃える理由: 2026-10-24 から元PCのフォルダ名も版番号なしの `mousemaster`。skill `/mm` とハーネスの `run.sh` はまずこの名前を探し、無ければ `mousemaster*` の版番号最大に落ちる。）
2. `mousemaster.exe` と `mousemaster.properties` を置き、**1a のハッシュを照合**。
3. 付録Aから最低限 `mousemaster-start.bat`, `mousemaster-autostart.bat`, `stop-mousemaster.bat`, `show-version.bat`, `restore-cursor.bat`, `restore-cursor.ps1` を作る（ASCII+CRLF）。
4. 旧 v64 が動いていたら止める（2.0(1)）。
5. `show-version.bat` → 出力をユーザーに見せる（元PC側と照合したい）。
6. `mousemaster-start.bat` をダブルクリック。`/MIN` で畳まれた窓が出て、`hide-console=true` により約1秒で消える。**`mousemaster.log` がフォルダに生成される**のが起動の証拠。
7. 動作: `leftctrl+leftalt` で normal-mode → `f` でヒント → `esc`。`q` で idle-mode。
8. **ここで数日〜1週間、手動起動のまま普段使いする。** 問題が無ければ次へ。何か引っかかれば、その時点で「フル構成にしない」と決められる。先に全部入れると切り分けられない。

### 2.2 分岐A: 管理者権限あり → 昇格自動起動（フル構成）

なぜ昇格か: 昇格していないと UIAccess が取れず、タスクバー・通知フライアウト・昇格ウィンドウ（タスクマネージャー等）の上に UI ヒントが出ない。元PCは 2026-08-28 からこの運用。

1. 付録Aの残り（`setup-admin-autostart.bat/.ps1`, `start-mousemaster-admin.bat`, `check-admin-setup.bat/.ps1`, `add-start-menu-shortcut.bat/.ps1`）を作る。
2. 動いている mousemaster を `stop-mousemaster.bat` で止める（UAC が1回出る）。
3. `setup-admin-autostart.bat` をダブルクリック → 自分で UAC を出して昇格 → スケジュールタスク `mousemaster-admin`（ログオン時・RunLevel Highest・IgnoreNew）を登録し、Startup フォルダの `mousemaster-prewarm.lnk` があれば `.disabled` にする。
4. `start-mousemaster-admin.bat` で即時起動（タスク経由なので UAC は出ない）。
5. `check-admin-setup.bat` で診断。§1〜4 は読むだけ、§5 はタスクを実際に叩く（起動テスト）。`run level : Highest` と `last result: 0x0` を確認。
6. `add-start-menu-shortcut.bat` → スタートメニューに「mousemaster (admin)」。PowerToys Run があれば `mou` で出る。
7. 一度サインアウト→サインインし、勝手に立ち上がる（`autostart-timing.log` に行が増える）ことを確認。

**フォルダを改名・移動したら** `setup-admin-autostart.bat` をもう一度叩く（タスクは絶対パスを持つので、黙って死ぬ）。

### 2.3 分岐B: 管理者権限なし → Startup ショートカットで自動起動（非昇格）

- 諦めるもの: 昇格ウィンドウ上のヒント、通知フライアウト上のヒント。それ以外は動く。
- 付録Aの `fix-autostart-target.bat` をダブルクリック → `%APPDATA%\...\Startup\mousemaster-prewarm.lnk` を作り（無ければ新規作成、あれば張り直し）、`mousemaster-autostart.bat` に向ける。管理者権限不要。
- **A と B は排他**。A の `setup-admin-autostart.ps1` は B のショートカットを `.disabled` にする（二重起動防止）。後から A に切り替えるなら A の手順をそのまま実行すればよい。
- 手動で止めるのは `stop-mousemaster.bat`（非昇格でも UAC は出るが通る。UAC 自体が出せない環境ならタスクマネージャーから「タスクの終了」→ 次回起動でカーソルは自動修復される）。

### 2.4 Windows 側の設定（両分岐共通）

| 設定 | 内容 | 理由 |
|---|---|---|
| **Mouse Vanish を OFF** | `main.cpl`（マウスのプロパティ）> ポインター オプション > 「文字の入力中にポインターを非表示にする」の**チェックを外す** | `render-as-cursor=true` の運用と相性が悪く、入力中にカーソルとインジケーターが消える（GitHub #86 で確定。元PCは 2026-08-16 から OFF） |
| PowerToys があるなら **Always On Top を機能ごとオフ** | PowerToys 設定 > Always On Top > 無効 | 設定が仮想デスクトップ切替で Win+Ctrl+矢印 を送る間に `t` が混ざると Win+Ctrl+T（AoT）が成立し、窓が最前面に貼り付く。元PCで 6 回踏んで機能ごと切った |
| PowerToys Keyboard Manager の NumLock→Disable | **やらない** | 元PC（ノート）固有の誤爆対策。副作用（Kinesis の NumLk も死ぬ）もある |
| 「タスクバーの位置」等のシェル設定 | **触らない** | スコープ外（1c） |

### 2.5 任意（最後に、余裕があれば）

- **待機カーソル**（アーク・ブルーム赤）: `cursors\` の 1a の 5 ファイルを導入先のフォルダの `cursors\` に置き、`pick-cursor.bat` で **3** を選ぶ。戻すのは **0** または `remove-spinner-cursors.bat`（`backup-cursors.reg` は元PCの原本なので導入先PCでは「Windows 標準に戻す」用途にだけ使う）。**差し替えたら mousemaster を再起動**（normal-mode は起動時に撮ったカーソルのスナップショットを使い続けるため。元PCで確認済み）。
- `claude-to-front.ahk`: 入れない（1c）。

### 2.6 任意: 即停止「alt+e → stop」とアイコン（元PCで 2026-10-04 に追加。丸ごと飛ばしてよい）

元PCでは、ゲームの前などに mousemaster を **UAC なしで一発で落とす**ために、スタートメニューに「mousemaster stop」を置き、PowerToys Run（alt+e）で `stop` と打って Enter で止めている。無くても本体は動く。止めるだけなら `stop-mousemaster.bat`（UAC 1回）かタスクマネージャーで足りる。**導入先PCで難しければここは飛ばす。** 入れるなら 2.2 / 2.3 が終わって落ち着いてから。

| 分岐 | 入れ方 | 何が起きるか |
|---|---|---|
| A（昇格運用） | `setup-stop-task.bat` をダブルクリック（UAC 1回。自分で昇格して `setup-stop-task.ps1` を走らせる） | オンデマンドのタスク `mousemaster-stop`（トリガー無し・RunLevel Highest）を登録し、スタートメニューに「mousemaster stop」（→ `stop-mousemaster-admin.bat` ＝ `schtasks /Run`）を作る。以後 UAC 無しで止まる |
| B（非昇格運用） | `setup-stop-shortcut.bat` をダブルクリック（管理者権限不要） | タスクは作らない。「mousemaster stop」（→ `stop-mousemaster-direct.bat`。非昇格の mousemaster を直接 kill）を作り、起動用の「mousemaster」（→ `mousemaster-start.bat`）が無ければそれも作る。以後 `mou` で起動・`stop` で停止 |

どちらも中身は `stop-mousemaster-task.ps1`（`Stop-Process -Force` → `SPI_SETCURSORS` でシステムカーソルを戻す。結果は `mm-stop.log` に1行ずつ）。**A の環境で B の `stop-mousemaster-direct.bat` を使っても止まらない**（非昇格から昇格プロセスは落とせない。`mm-stop.log` に `still running after kill` と残る）。逆（B の環境で A のスクリプト）はタスクが無いので動かない。分岐に合わせること。

使い方: PowerToys Run があれば alt+e（元PCの設定。PowerToys の既定は alt+space）→ `stop` → Enter。**PowerToys が無ければ Windows キー → `mousemaster stop` と打って Enter**（スタートメニューの検索。同じショートカットが起動する）。PowerToys は無くてよいし、このために入れなくてよい。

アイコン（任意の任意）: 1a の `mm4-start.ico` / `mm4-stop.ico` を導入先のフォルダに置いて `set-mousemaster-icons.bat`（管理者権限不要）。「mousemaster」「mousemaster (admin)」「mousemaster stop」のうち存在するものに貼る。PowerToys Run はアイコンをキャッシュするので、変わって見えないときは PowerToys をトレイから終了して起動し直す。.ico が無ければマウスのコントロールパネルのアイコンのままで、動作に差はない。

入らないときの逃げ道（上から順に）:
- PowerShell スクリプトの実行が止められている（実行ポリシー等）→ 2.1 の他のスクリプトも同じ条件なので、そこで既に分かっているはず。即停止だけなら `taskkill /F /IM mousemaster.exe` の1行の .bat でも止まる（カーソルは次回起動時に mousemaster が自分で直す。issue 83）。昇格運用ならその .bat に UAC が出る。
- スケジュールタスクの登録が禁止されている（A で `Register-ScheduledTask` が失敗。`setup-stop-task.log` に `FAILED:` が残る）→ B の `setup-stop-shortcut.bat` にする。ただし昇格した mousemaster は止められないので、止めるのは `stop-mousemaster.bat`（UAC）のまま。
- スタートメニューの `Programs` フォルダに書けない → 入口を諦める。`stop-mousemaster-admin.bat` / `stop-mousemaster-direct.bat` をダブルクリックしても同じことが起きる（ショートカットはただの入口）。

戻す: A は `remove-stop-task.bat`（タスク削除＋ショートカット削除、UAC 1回）。B は `%APPDATA%\Microsoft\Windows\Start Menu\Programs\mousemaster stop.lnk` を消すだけ。

## 3. `mousemaster.properties` について導入先PCで知っておくこと

- **絶対パス・ユーザー名は含まれていない**（grep で確認）。そのまま置ける。
- 前提にしている環境: jp-kana-jis、Mouse Vanish OFF、`hide-console=true`（`mousemaster-start.bat` の `/MIN` と対になっている。片方だけ変えない）。
- `logging.level=INFO` / `logging.key-redaction=pseudonymize` — このまま。TRACE にすると打鍵が平文でログに残る。
- `ui-hint-mode.hint.type=ui-vision`、`ui-area=active-screen` — 作者の画像認識ベースの UI ヒント。GPU に依存するので**導入先PCで `a` のヒントが遅い・出ないなら、`ui-hint-mode.hint.type=ui-accessibility` と `ui-hint-mode.hint.ui-area=active-window` の組（実測 55〜96ms、元PCで長く常用した安定版）に変える**。（3.5 節の「○」の代表例）。変えたらユーザーに伝える。
- アプリ条件付きのバインド（Claude アプリ限定の ctrl+, / ctrl+m ズーム、OneCommander の alt+g 素通し、ZoomIt の ctrl+i/k/l 素通し、Brave）は、そのアプリが無ければ**不活性なだけ**。害はない。
- 変更履歴はファイル先頭のヘッダ [1]〜[28] に全部ある。読めば「なぜそうなっているか」が分かる。
- **導入先PCで変えてよいもの（○、ハーネス無しで安全）**: 数値だけの調整（`hint.font-size`、`hint.grid-cell-width/height`、`zoom.percent`、`indicator.size`、速度系）、`ui-hint-mode.hint.type` / `ui-area` の切替、既にある行を `#` でコメントアウトして**機能を止める**こと。変えたら導入先側 CLAUDE.md に1行ずつ記録し、ユーザーに伝える（元PC側に取り込む）。
- **導入先PCで変えてはいけないもの（×）**: コンボの追加・変更、`_{...}` / `^{...}` のガード、`remapping.*`、`macro.*`、`key-alias`、`app-alias`。ここが崩れると ctrl+c / ctrl+v / alt+tab / Win+D / alt+h が**黙って**死ぬ。元PCのハーネス（301項目）がそれを見張っているので、この種の変更は「導入先側 CLAUDE.md の未着手に書く → 元PCで直してハーネスを通す → properties をファイルごと運ぶ」で行う。
- 元PC側の不変条件のうち導入先PCでも効くもの:
  - 裸の `+key` コンボは修飾キー保持中にも一致する → 現行設定はガード済み。**追記しない**。
  - 値の末尾の `\` は `\\` と書く（1つだと次行を飲む）。
  - 設定を書き換えても自動リロードが効かない時がある → `mousemaster.log` の末尾で `Reloaded configuration file` を確認。出ていなければ再起動。

### 3.4 ○ の変更は導入先側 Claude が行う（ユーザーは症状を言って、押して確かめるだけ）

導入先側 Claude はこの元PC側と同じ道具を持つ（フォルダを繋げば `mousemaster.properties` と `mousemaster.log` を読み書きできる）。
ユーザーがやるのは「ヒントの字が小さい」と言うことと、直した後にキーを押して見ること。編集・確認・記録は Claude。

手順（元PC側で1年やってきた作法。省略しない）:

1. **先に退避**: `mousemaster.properties.bak-<何の変更か>-<日付>` をコピーで作る（元PCには 40 個以上ある。消さない）。
2. **1回に1つだけ変える**。2つ同時に変えると、効いたのがどちらか分からなくなる。
3. **書き方はその場で上書き**（python の `open(p, 'w')` で書き直す等）。`sed -i` や `mv` で置き換えると変更通知が飛ばず、**リロードされない**（元PCで実測）。
4. **`mousemaster.log` の末尾で `Reloaded configuration file` を確認**。出ていなければ同じ内容をもう一度その場で書く。それでも出なければ `stop-mousemaster.bat` → 起動し直す（分岐Aは `start-mousemaster-admin.bat`、Bは `mousemaster-start.bat`）。
   `Unable to load configuration file` が1回出ても、直後の変更イベントで読み直されるので実害はない。
5. ユーザーに押してもらって確認。だめなら 1 の退避ファイルをその場で上書きコピーして戻す（これもその場で上書き）。
6. 導入先側 CLAUDE.md の「現在地」に **何を・なぜ・いくつからいくつへ** を1行で記録。元PC側に取り込むため、8章の報告テンプレの「変えた設定」にも書く。

× の要望（コンボ・ガード・remapping・macro）が出たら、**直さずに**「未着手・保留」に症状と再現手順を書く。それだけでよい。

### 3.5 環境の違いで起きやすいこと（一発で同じにはならない前提）

| 起きやすいこと | 何が違うから | 対処 | 導入先PCで直せるか |
|---|---|---|---|
| `a` の UI ヒントが遅い・出ない | ui-vision が GPU 依存 | `ui-accessibility` + `active-window` に | ○ |
| ヒントの文字・格子・インジケーターが大きすぎ／小さすぎ | 解像度・DPI（元PCは 3440x1440 ウルトラワイド）、モニタ枚数 | `hint.font-size`（今 16。元PCでも 14〜18 で調整中）、hint2 のセル 10x15px、`zoom.percent=5`、`indicator.size` | ○ |
| **Office で alt+H / alt+A が効かない** | `leftalt+a` / `leftalt+h`（仮想デスクトップ切替）は idle-mode でも生きている。Excel/Word のリボンのキーヒント（alt+H=ホーム、alt+A=データ）と衝突する。元PCは Office を使わないので踏んでいない | アプリ条件（`app-alias` + `_{...}`）で Office を除外するか、キーを変える。**コンボ変更なので元PC側で** | × |
| 導入先のツールのホットキーと衝突 | idle-mode でも生きているバインド（alt+a/h は確実。alt+ijkl 矢印、leftshift+@ 等はモードを要確認）と重なる | 同上 | × |
| alt+e で PowerToys Run が出ない／別のものが出る | PowerToys Run のホットキーは元PCで alt+e に変えてある（既定は alt+space）。導入先PCの PowerToys は既定のまま、または無い | PowerToys 設定 > PowerToys Run > 起動のショートカットを合わせる。無ければ Windows キー検索で代用（2.6） | ○（Windows 側の設定） |
| RDP / VDI / Citrix の窓の中で効かない・挙動が違う | 低レベルフックはローカル側にしか無い。リモート窓の中では向こうのキー処理になる | 仕様。リモート窓の外でだけ使う | — |
| IME 周りの誤爆 | IME の種類・トグルキーが違う | 記録して元PC側で | × |
| **alt+g が OneCommander で効かない**（alt+f / alt+c 等は効く、mousemaster を止めても効かない） | NVIDIA アプリの G-Assist が **Alt+G をグローバルホットキーで掴む**（元PCで 2026-10-07 に発生。NVIDIA が勝手に更新して掴んだ。ゲーム外では何も起きないので「効かない」に見える） | `check-altg-hotkey.bat`（A24/A25）を実行 → alt+g が TAKEN なら NVIDIA アプリ → 設定 → NVIDIA オーバーレイをオフ、またはオーバーレイ（Alt+Z）→ 歯車 → キーボードショートカットで G-Assist のキーを変える。他のキーでも同じ手が使える（ps1 の Probe 行を足す） | ○ |
| 何も押していないのにカーソルが走り続ける | 移動キーを押したまま別モードに入り、離しがそのモードに落ちて StopMove が出ない型（元PC 2026-10-07。arrowkey / temp-ZoomIt / screen-selection の 3 モードは [30] で塞いである）。別の型は「離しイベントの消失」（10 秒で暴走ブレーカー [28] が止める。モード跨ぎではブレーカーも効かない） | 止めるには同じ方向キーを押して離す。**何秒で止まったか・何を押して止まったかを記録**して元PC側へ（ハーネス M51/M52 の総当たりで再現できる） | × |
| 昇格ウィンドウ・通知フライアウトの上で効かない | 分岐B（非昇格） | 仕様 | — |
| normal-mode で `z` を押すと F1 が飛ぶ（ヘルプが開く等） | [31] Snipaste 連携: `z` は Snipaste のスニップ開始ホットキー F1 をどのアプリでも注入する。元PCでは Snipaste（ポータブル、Downloads\mousemaster\Snipaste-2.11.3-x64、ホットキー既定）を常駐させている | Snipaste を導入先PCにも入れる（zip 展開のみ・インストール不要。設定は同じフォルダの `config.ini` に入るので、元PCの `config.ini` を一緒にコピーすれば揃う: `[Snip] show_tips=false`＝切り取り中の左下のホットキー一覧を出さない、`ask_for_confirm_on_esc=false`＝Esc の確認なし、`[General] start_on_boot=true`＝Snipaste 自身のスタートアップ登録）か、入れないなら properties 末尾 [31] の `app-alias.snipaste`、`virtual-key.snip`、`normal-mode.remapping.snip*` の計 7 行と [31b] の `normal-mode.remapping.unpinoldest` / `arrowkey-mode.remapping.unpinoldest` を `#` でコメントアウト。[31b] の Alt+Z は F14 を送るだけで、受け手の `snipaste-unpin.ahk`（AutoHotkey 常駐）は 1c の方針どおり導入先PCには入れない（F14 は他のアプリでは無視される） | ○ |

**運用**: 最初の1週間は「直さずに記録する」。導入先側 CLAUDE.md の「未着手・保留」に溜め、○ はその場で、× はまとめて元PC側で直して properties を**1回だけ**運び直す。往復は1〜2回で収まる想定。
ハーネスを導入先PCに入れずに済ませる手として、導入先側 Claude のクラウド側でハーネスを回す案もある（元PCでも実機・クラウド両方で回している）。× が多くなったら別途準備する。

## 4. 導入後チェック

| # | 確認 | 分岐 |
|---|---|---|
| 1 | `mousemaster.log` が更新される／`Loaded configuration file` が出ている | A/B |
| 2 | `leftctrl+leftalt` → `f` でヒントが出て、ラベルで飛ぶ | A/B |
| 3 | 中クリック `\`、左トグル `n`（`n` で掴んで `f` で飛んで `n` で離す＝ドラッグ&ドロップ） | A/B |
| 4 | ctrl+c / ctrl+v / alt+tab / Win+D が普通に効く（ガード漏れ検出） | A/B |
| 5 | サインアウト→サインイン後に自動で立ち上がる | A/B |
| 6 | タスクマネージャーを前面にしても効く／通知フライアウトの上に `a` のヒントが出る | A のみ |
| 7 | `check-admin-setup.bat` で `run level : Highest`、`last result: 0x0` | A のみ |
| 8 | `Get-Process mousemaster` が**1つ**（旧 v64 と二重になっていない） | A/B |
| 9 | （2.6 を入れた場合）「mousemaster stop」で止まり、`mm-stop.log` に `killed pid` と `SPI_SETCURSORS ok=True` が出る。カーソルが標準に戻る。`mou`（または `mousemaster-start.bat`）で再起動できる | A/B |

## 5. 使わないスクリプト（罠）

- **`restart-mousemaster.bat`**: `taskkill /IM mousemaster.exe` に `/F` が無く、コンソールアプリは WM_CLOSE を無視するので**止まらない**（2026-08-14 実測）。その直後に exe を**ガード無しで直接起動**するので二重起動になり得る。元PCにも残っているが使っていない。止める→起動は `stop-mousemaster.bat` → `start-mousemaster-admin.bat`（A）または `mousemaster-start.bat`（B）で行う。

## 6. ロールバック

- 新しい方を止める: `stop-mousemaster.bat`。分岐Aなら `schtasks /Delete /TN mousemaster-admin /F`（管理者）、分岐Bなら Startup の `mousemaster-prewarm.lnk` を消す。
- 旧 v64 は触っていないので、止めた起動口を戻せば元どおり。

## 7. 導入先PC側に作る `CLAUDE.md` の雛形

```markdown
# mousemaster（導入先PC）— 引き継ぎ文書

> Claudeへ: この文書はあなたが維持する。ここは元PCの構成を YYYY-MM-DD に写した複製。
> 正本は元PC側。ここで mousemaster.properties を編集しない。

## 1. これは何か
Win11 / <機種> / <配列> で mousemaster を運用。元PCの SETUP.md に従って導入。

## 2. 不変条件
- mousemaster.properties の編集は PLAN 3章の ○/× に従う。○（数値・切替・コメントアウト）は可、×（コンボ・ガード・remapping・macro）は不可。変えたら1行ずつここに記録し、× の要望は「未着手・保留」へ
- ハーネス・git・issue 監視は無い。skill /mm のハーネス手順は適用外
- 二重起動しない。旧 v64（<場所>）の起動口は <方法> で止めてある

## 3. 現在地
- exe: nightly 96c7f26、sha256 b131a820…（照合日 YYYY-MM-DD）
- properties: sha256 1115bcaf…（102,172 byte、2026-10-12 版。正は 1a 節と `SHA256SUMS.txt`。更新のたびに転記）
- 分岐: A（昇格タスク mousemaster-admin）/ B（Startup ショートカット）
- 即停止（2.6）: 入れた（A: タスク mousemaster-stop / B: 直接 kill）/ 入れていない（理由: ）。アイコン: 貼った / 貼っていない
- 導入後チェック（4章）の結果: ...

## 4. ファイル索引
（付録Aのうち置いたもの）

## 5. 未着手・保留
```

## 8. 元PC側へ返す報告テンプレ（ユーザーが元PCの Claude に貼る）

```
導入先PC移行 結果（YYYY-MM-DD）
- 分岐: A(昇格) / B(非昇格) / 未導入（理由: ）
- ハッシュ照合: exe ○/× properties ○/×   show-version: <出力1行>
- 旧v64: 場所=<path> / 自動起動=<あった→止め方 / なかった>
- 4章チェック: 1○ 2○ 3○ 4○ 5○ 6○ 7○ 8○ 9○（該当分のみ）
- 即停止(2.6): 入れた(A/B) / 入れていない（理由: ）
- 変えた設定: <なし / ui-vision→ui-accessibility 等>
- 引っかかった点: <なし / 内容>
```

---

## 付録A: スクリプト全文（25本。A1〜A14 は元PC `mousemaster`（2026-10-24 までは `mousemaster_92`） の 2026-09-25 時点、A15〜A23 は 2026-10-06 時点、A24〜A25 は 2026-10-07 時点と同一）

保存規則: **ASCII・CRLF**、ファイル名は見出しどおり、導入先のフォルダ直下に置く。
Claude が書く場合は、書いたあと `(Get-Content -Raw .\<file>) -match "`r`n"` が True になることを確認する。

### A1. `mousemaster-start.bat` — 手動起動（二重起動ガード付き）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Launch mousemaster.
rem
rem  --pre-warm-hints=true is kept for safety but is a NO-OP since v91: the
rem  author made pre-warming the default. On v91 with no flag at all, 23 taps
rem  of f gave +f 23 / -f 23 / mode switch 23, and the first mesh build was
rem  1-2ms instead of ~620ms. See GitHub issue #74 (fixed).
rem
rem  Quit any running mousemaster before running this.
rem  taskkill /F used to leave the hooks installed (issue #75). v92 exits
rem  cleanly, but quitting it normally is still the right habit.
rem
rem  NOTE: batch files here must be ASCII with CRLF line endings. An echo line
rem        must never contain a bare ^> and neither must a rem line - cmd still
rem        performs the redirection and truncates that file.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
rem 2026-08-23: idempotent guard - never start a second instance
rem (hibernate-resume fires the ONLOGON task while the old instance is alive,
rem  and two instances fight over the hooks and both go insane)
tasklist /FI "IMAGENAME eq mousemaster.exe" | find /I "mousemaster.exe" >nul
if not errorlevel 1 (
    echo mousemaster is already running - nothing to do.
    exit /b
)
rem 2026-09-02: /MIN so the console cannot be clicked into selection mode during
rem the ~1s between process start and the config load that hides it
rem (hide-console=true in mousemaster.properties). A minimised window takes no
rem mouse clicks, and it stays reachable from the taskbar if the config fails.
start "" /MIN "%~dp0mousemaster.exe" --pre-warm-hints=true
```

### A2. `mousemaster-autostart.bat` — 自動起動の入口（タスク／Startup ショートカットはこれを指す）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Autostart wrapper. The Startup shortcut points HERE, not at the exe, so
rem  a delay can be reintroduced without touching the Startup folder (that
rem  folder cannot be edited from Cowork).
rem
rem  No wait: the old batch waited 4s for the desktop to come up. That felt
rem  slow, was shortened to 2s, then removed entirely on 2026-08-02 with no
rem  ill effects. If starting too early ever causes trouble, put it back:
rem      timeout /t 2 /nobreak ^>nul
rem ---------------------------------------------------------------------------
echo %DATE% %TIME% task-fired >> "%~dp0autostart-timing.log"
call "%~dp0mousemaster-start.bat"
echo %DATE% %TIME% start-bat-returned >> "%~dp0autostart-timing.log"
```

### A3. `setup-admin-autostart.bat` — 分岐A: 昇格タスク登録（自分で UAC を出す）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Switch mousemaster's autostart to an ELEVATED scheduled task.
rem
rem  Why: only an elevated mousemaster can duplicate winlogon's token and get
rem  UIAccess, which is what lets hints draw over the taskbar, the notification
rem  flyout and elevated windows (GitHub issue #98, README step 5).
rem
rem  A Startup-folder shortcut cannot start a program elevated. A scheduled
rem  task with "run with highest privileges" can, and does it without a UAC
rem  prompt, so autostart stays silent.
rem
rem  This script needs admin rights itself; it re-launches itself elevated if
rem  you just double-click it (one UAC prompt, only during setup).
rem
rem  Undo with undo-admin-autostart.bat. Nothing is deleted: the Startup
rem  shortcut is renamed to .lnk.disabled and can be restored.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-admin-autostart.ps1"
echo.
pause
```

### A4. `setup-admin-autostart.ps1` — A3 の本体

```powershell
# Registers an elevated logon task for mousemaster and disables the Startup
# shortcut, so exactly one instance starts and it starts with admin rights.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$taskName = 'mousemaster-admin'
$target = Join-Path $here 'mousemaster-autostart.bat'
$user = "$env:USERDOMAIN\$env:USERNAME"

Write-Host ''
Write-Host '=== 1. Checking prerequisites ==='
if (-not (Test-Path $target)) {
    throw "Not found: $target  (run this from the mousemaster folder)"
}
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run elevated. Use setup-admin-autostart.bat.'
}
Write-Host "  target : $target"
Write-Host "  user   : $user"

Write-Host ''
Write-Host '=== 2. Registering the scheduled task ==='
# Written as XML rather than schtasks flags: only XML can set the working
# directory, and IgnoreNew is what stops a resume from starting a second copy.
$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Start mousemaster elevated at logon, so its overlay gets UIAccess (hints over the taskbar, the notification flyout and elevated windows).</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$user</UserId>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$user</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>5</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$target</Command>
      <WorkingDirectory>$here</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
$xmlPath = Join-Path $env:TEMP 'mousemaster-admin-task.xml'
# schtasks reads the XML as UTF-16.
Set-Content -Path $xmlPath -Value $xml -Encoding Unicode
$out = & schtasks /Create /TN $taskName /XML $xmlPath /F 2>&1
Write-Host ("  " + ($out -join "`n  "))
if ($LASTEXITCODE -ne 0) { throw "schtasks /Create failed with exit code $LASTEXITCODE" }
Remove-Item $xmlPath -Force

Write-Host ''
Write-Host '=== 3. Disabling the old Startup shortcut ==='
# Two instances fight over the keyboard hook, so the non-elevated launcher has
# to go. Renamed, not deleted: undo-admin-autostart.bat puts it back.
$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk'
if (Test-Path $lnk) {
    $disabled = "$lnk.disabled"
    if (Test-Path $disabled) { Remove-Item $disabled -Force }
    Rename-Item -Path $lnk -NewName (Split-Path $disabled -Leaf)
    Write-Host "  renamed to mousemaster-prewarm.lnk.disabled"
} else {
    Write-Host '  already absent - nothing to do'
}

Write-Host ''
Write-Host '=== 4. Verifying ==='
$q = & schtasks /Query /TN $taskName /FO LIST 2>&1
Write-Host ("  " + (($q | Select-String 'TaskName|Status|Next Run') -join "`n  "))
Write-Host ''
Write-Host 'DONE. From the next logon, mousemaster starts elevated with no UAC prompt.'
Write-Host ''
Write-Host 'To start it elevated right now:'
Write-Host '  1. quit the mousemaster that is running (tray icon or its console window)'
Write-Host '  2. run start-mousemaster-admin.bat'
Write-Host ''
Write-Host 'To check it worked: the console must NOT show'
Write-Host '  "Failed OpenProcess winlogon 5"'
Write-Host 'and UI hints should now appear over the taskbar and the notification flyout.'
```

### A5. `start-mousemaster-admin.bat` — 分岐A: 今すぐ昇格起動（UAC なし。A3 実行後のみ）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Start mousemaster elevated right now, with no UAC prompt.
rem
rem  It asks the scheduled task to run, and the task carries the elevated token,
rem  so no consent dialog appears. Requires setup-admin-autostart.bat to have
rem  been run once.
rem
rem  Nothing happens if mousemaster is already running: mousemaster-start.bat
rem  refuses to start a second instance (two of them fight over the hooks).
rem  Quit the running one first if you meant to restart it.
rem
rem  Silent on success - this is also what the "mousemaster (admin)" Start menu
rem  shortcut runs, and a leftover console window on every launch is noise.
rem ---------------------------------------------------------------------------
schtasks /Run /TN "mousemaster-admin" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: could not start the task "mousemaster-admin".
    echo Has setup-admin-autostart.bat been run?
    echo.
    pause
)
```

### A6. `check-admin-setup.bat` — 診断（§1〜4 読むだけ、§5 はタスク起動テスト）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Report the actual state of the elevated-autostart setup, so we stop
rem  guessing: the scheduled task, both shortcuts, and the running process.
rem  No admin rights needed; nothing is modified.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-admin-setup.ps1"
echo.
pause
```

### A7. `check-admin-setup.ps1` — A6 の本体

```powershell
# Reports the real state of the elevated-autostart setup.
# Uses the ScheduledTasks cmdlets rather than parsing schtasks output: schtasks
# prints localized labels, and grepping English ones silently found nothing on a
# Japanese Windows (which is what made the first version of this script useless).
$ErrorActionPreference = 'Continue'
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startup  = Join-Path $programs 'Startup'
$shell = New-Object -ComObject WScript.Shell

function ShowLnk($file) {
    $s = $shell.CreateShortcut($file.FullName)
    Write-Host ("    {0}" -f $file.Name)
    Write-Host ("       -> {0} {1}" -f $s.TargetPath, $s.Arguments)
}

Write-Host ''
Write-Host '=== 1. Scheduled tasks matching *mousemaster* ==='
$tasks = Get-ScheduledTask -TaskName '*mousemaster*' -ErrorAction SilentlyContinue
if (-not $tasks) {
    Write-Host '  none - run setup-admin-autostart.bat'
} else {
    foreach ($t in $tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
        Write-Host ("  name      : {0}{1}" -f $t.TaskPath, $t.TaskName)
        Write-Host ("  state     : {0}" -f $t.State)
        Write-Host ("  run level : {0}   (Highest = elevated)" -f $t.Principal.RunLevel)
        foreach ($a in $t.Actions) {
            Write-Host ("  action    : {0} {1}" -f $a.Execute, $a.Arguments)
            if ($a.WorkingDirectory) { Write-Host ("  workdir   : {0}" -f $a.WorkingDirectory) }
        }
        foreach ($tr in $t.Triggers) { Write-Host ("  trigger   : {0}" -f $tr.CimClass.CimClassName) }
        if ($info) {
            Write-Host ("  last run  : {0}" -f $info.LastRunTime)
            Write-Host ("  last result: 0x{0:X}   (0 = ok)" -f $info.LastTaskResult)
            Write-Host ("  next run  : {0}" -f $info.NextRunTime)
        }
        Write-Host ''
    }
}

Write-Host '=== 2. Start menu entries matching *mousemaster* (what PowerToys Run offers) ==='
$found = Get-ChildItem -Path $programs -Recurse -Filter '*mousemaster*' -ErrorAction SilentlyContinue
if ($found) {
    foreach ($f in $found) {
        # CreateShortcut only accepts .lnk/.url; a .bak beside them threw a COM error.
        if ($f.Extension -eq '.lnk') { ShowLnk $f } else { Write-Host ("    {0}   (not a shortcut)" -f $f.Name) }
    }
} else { Write-Host '    (none)' }

Write-Host ''
Write-Host '=== 3. Startup folder (everything in it) ==='
$su = Get-ChildItem -Path $startup -ErrorAction SilentlyContinue
if ($su) { foreach ($f in $su) { Write-Host ("    " + $f.Name) } } else { Write-Host '    (empty)' }

Write-Host ''
Write-Host '=== 4. Running process ==='
$p = Get-Process mousemaster -ErrorAction SilentlyContinue
if ($p) {
    foreach ($proc in $p) { Write-Host ("  running: pid {0}, started {1}" -f $proc.Id, $proc.StartTime) }
} else {
    Write-Host '  not running'
}

Write-Host ''
Write-Host '=== 5. Can the task be started right now? ==='
Write-Host '  (this actually runs it - mousemaster should appear)'
$r = & schtasks /Run /TN 'mousemaster-admin' 2>&1
Write-Host ("  schtasks exit code: {0}" -f $LASTEXITCODE)
Write-Host ("  " + ($r -join "`n  "))
Start-Sleep -Seconds 3
$p2 = Get-Process mousemaster -ErrorAction SilentlyContinue
if ($p2) {
    Write-Host '  -> mousemaster is now running.'
} else {
    Write-Host '  -> still not running. Check autostart-timing.log next to this script,'
    Write-Host '     and mousemaster.log, for what the batch did.'
}
```

### A8. `add-start-menu-shortcut.bat` — 分岐A: スタートメニューに「mousemaster (admin)」

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Put a "mousemaster (admin)" entry in the Start menu, so PowerToys Run
rem  (and the Start menu itself) can launch mousemaster elevated by name.
rem
rem  Why this is needed: setup-admin-autostart.bat disabled the Startup-folder
rem  shortcut, and that shortcut was what PowerToys Run used to find when you
rem  typed "mou". This puts a searchable entry back - one that starts the
rem  elevated scheduled task, so there is no UAC prompt.
rem
rem  No admin rights needed: it only writes into your own Start menu folder.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0add-start-menu-shortcut.ps1"
echo.
pause
```

### A9. `add-start-menu-shortcut.ps1` — A8 の本体

```powershell
# Creates a Start-menu shortcut that launches mousemaster through its elevated
# scheduled task (no UAC prompt), so name-based launchers can find it again.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$target = Join-Path $here 'start-mousemaster-admin.bat'
if (-not (Test-Path $target)) { throw "Not found: $target" }

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$lnk = Join-Path $startMenu 'mousemaster (admin).lnk'

$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut($lnk)
$s.TargetPath = $target
$s.WorkingDirectory = $here
$s.Description = 'Start mousemaster elevated (via the mousemaster-admin scheduled task, no UAC prompt)'
$s.WindowStyle = 7   # minimised: the batch is silent on success
# The exe carries no icon resource of its own, so borrow the mouse control panel's.
$s.IconLocation = "$env:SystemRoot\System32\main.cpl,0"
$s.Save()

Write-Host ''
Write-Host "Created: $lnk"
Write-Host "  target: $target"
Write-Host ''
Write-Host 'PowerToys Run may take a moment to re-index. Type "mousemaster" or "mou".'
Write-Host 'Launching it starts mousemaster elevated with no UAC prompt.'
Write-Host ''
Write-Host 'Note: if mousemaster is already running, nothing happens by design -'
Write-Host 'a second instance would fight the first one over the keyboard hooks.'
```

### A10. `fix-autostart-target.bat` — 分岐B: Startup ショートカットを作る／張り直す（管理者不要）

```bat
@echo off
cd /d "%~dp0"
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk"

echo ============================================================
echo   Repoint the startup shortcut at THIS folder
echo ============================================================
echo.
echo   RUN THIS WHENEVER YOU RENAME THE MOUSEMASTER FOLDER.
echo   The Startup shortcut stores an absolute path, so a rename
echo   silently breaks autostart with no error message.
echo.
echo   Only this one shortcut is modified:
echo      mousemaster-prewarm.lnk
echo   New target:
echo      %~dp0mousemaster-autostart.bat
echo   Nothing else is touched, nothing is deleted.
echo.
echo   Press Ctrl+C to cancel, or
pause
echo.
powershell -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $p=\"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk\"; $s=$w.CreateShortcut($p); $s.TargetPath='%~dp0mousemaster-autostart.bat'; $s.WorkingDirectory='%~dp0'; $s.WindowStyle=7; $s.Save(); $t=$w.CreateShortcut($p).TargetPath; Write-Host ('     target now: ' + $t); if (Test-Path $t) { Write-Host '     target exists: OK' } else { Write-Host '     WARNING: target does not exist' }"
echo.
echo   Done. Autostart now points at this folder.
echo.
pause
```

### A11. `stop-mousemaster.bat` — 確実に止める（UAC 1回）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Stop the running mousemaster, even when it runs elevated and its console
rem  window is hidden (hide-console=true), so there is no X to click.
rem
rem  An elevated process can only be killed by an elevated taskkill, so this
rem  asks for the UAC consent once. /F is required: without it taskkill only
rem  posts WM_CLOSE, which a console application ignores (measured 2026-08-14).
rem  The next start repairs the system cursor by itself (issue 83, 2261b7b).
rem ---------------------------------------------------------------------------
tasklist /FI "IMAGENAME eq mousemaster.exe" 2>nul | find /I "mousemaster.exe" >nul
if errorlevel 1 (
    echo mousemaster is not running.
    goto :end
)
powershell -NoProfile -Command "Start-Process taskkill -ArgumentList '/F','/IM','mousemaster.exe' -Verb RunAs -Wait"
timeout /t 1 /nobreak >nul
tasklist /FI "IMAGENAME eq mousemaster.exe" 2>nul | find /I "mousemaster.exe" >nul
if errorlevel 1 (
    echo mousemaster stopped.
) else (
    echo mousemaster is still running - was the UAC prompt declined?
)
:end
echo.
pause
```

### A12. `restore-cursor.bat` — カーソルが戻らない時の救出

```bat
@echo off
chcp 437 >nul
title mousemaster cursor rescue
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-cursor.ps1"
echo.
pause
```

### A13. `restore-cursor.ps1` — A12 の本体

```powershell
$ErrorActionPreference = 'SilentlyContinue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'cursor-check.txt') -Force | Out-Null

Write-Host ""
Write-Host "=== 1. Is mousemaster still alive? ==="
$mm = Get-Process mousemaster
if ($mm) {
  foreach ($p in $mm) {
    Write-Host ("  ALIVE   pid={0}  started={1}" -f $p.Id, $p.StartTime)
    Write-Host ("          description={0}" -f $p.Description)
  }
  Write-Host ""
  Write-Host "  -> The process SURVIVED. This is issue #75, still broken for this case."
  Write-Host "     End 'mousemaster.exe' from Task Manager > Details to stop it."
} else {
  Write-Host "  not running"
  Write-Host ""
  Write-Host "  -> The process is gone but the cursor did not come back."
  Write-Host "     That is issue #72: SetSystemCursor was never undone."
}

Write-Host ""
Write-Host "=== 2. Console/terminal processes right now ==="
Get-Process | Where-Object { $_.ProcessName -match 'WindowsTerminal|OpenConsole|conhost|cmd|powershell|pwsh' } |
  ForEach-Object { Write-Host ("  {0,-20} pid={1}" -f $_.ProcessName, $_.Id) }

Write-Host ""
Write-Host "=== 3. Restore the default system cursors ==="
Write-Host "  This reloads the cursor scheme you already have configured in Windows."
Write-Host "  It changes nothing else and needs no reboot."
Write-Host ""
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Cur {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
}
"@
$ok = [Cur]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0)   # SPI_SETCURSORS
if ($ok) { Write-Host "  SPI_SETCURSORS: OK - cursors reloaded." }
else { Write-Host "  SPI_SETCURSORS failed. Signing out and back in also restores them." }

Write-Host ""
Write-Host "  Move the mouse and look at the pointer now."
Write-Host ""
Stop-Transcript | Out-Null
```

### A14. `show-version.bat` — 版の確認（出力をユーザー経由で元PC側と照合）

```bat
@echo off
cd /d "%~dp0"
echo ============================================================
echo   mousemaster version
echo ============================================================
echo.
"%~dp0mousemaster.exe" --version
echo.
echo   Tell Claude the line above.
echo.
pause
```

### A15. `setup-stop-task.bat` — 2.6 分岐A: 即停止タスクの登録（自分で UAC を出す）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  One-time setup: register the "mousemaster-stop" scheduled task and put a
rem  "mousemaster stop" entry in the Start menu.
rem
rem  Why a task: mousemaster runs elevated (mousemaster-admin), and only an
rem  elevated taskkill can end it. A task with "run with highest privileges"
rem  carries that token, so "mousemaster stop" works without a UAC prompt.
rem
rem  How to use it afterwards: alt+e (PowerToys Run), type stop, Enter.
rem  Start again with "mou", Enter, as before.
rem
rem  This script needs admin rights once; it re-launches itself elevated.
rem  Undo with remove-stop-task.bat.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-stop-task.ps1"
echo.
pause
```

### A16. `setup-stop-task.ps1` — A15 / A20 の本体（`-ShortcutOnly` で分岐B）

```powershell
# Registers the on-demand elevated task "mousemaster-stop" and a Start-menu
# shortcut "mousemaster stop" that fires it. Same idea as setup-admin-autostart.ps1,
# but built with the ScheduledTasks cmdlets instead of XML (no schema to get wrong).
# Everything printed here also goes to setup-stop-task.log next to this script.
#
# -ShortcutOnly (run by setup-stop-shortcut.bat): no task, no admin rights.
# The shortcut then runs stop-mousemaster-direct.bat, which kills a NON-elevated
# mousemaster directly. For a PC without admin rights (branch B of the plan),
# where mousemaster itself runs non-elevated.
param([switch]$ShortcutOnly)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
Start-Transcript -Path (Join-Path $here 'setup-stop-task.log') -Append | Out-Null
try {
    $taskName = 'mousemaster-stop'
    $worker = Join-Path $here 'stop-mousemaster-task.ps1'
    if ($ShortcutOnly) { $launcher = Join-Path $here 'stop-mousemaster-direct.bat' }
    else { $launcher = Join-Path $here 'stop-mousemaster-admin.bat' }
    $user = "$env:USERDOMAIN\$env:USERNAME"

    Write-Host ''
    Write-Host '=== 1. Checking prerequisites ==='
    foreach ($f in @($worker, $launcher)) {
        if (-not (Test-Path $f)) { throw "Not found: $f  (run this from the mousemaster folder)" }
    }
    if (-not $ShortcutOnly) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'This script must run elevated. Use setup-stop-task.bat.'
        }
    }
    Write-Host "  worker   : $worker"
    Write-Host "  launcher : $launcher"
    Write-Host "  user     : $user"

    Write-Host ''
    Write-Host '=== 2. Registering the on-demand task ==='
    if ($ShortcutOnly) {
        Write-Host '  skipped (-ShortcutOnly): no task. The shortcut kills a non-elevated mousemaster directly.'
    }
    else {
        # No trigger: it only runs when asked (schtasks /Run). RunLevel Highest is what
        # lets it end the elevated mousemaster without a UAC prompt. The worker runs
        # through powershell.exe with a hidden window so nothing flashes on screen.
        $workerArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $worker + '"'
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $workerArgs -WorkingDirectory $here
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
            -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -Priority 5
        Register-ScheduledTask -TaskName $taskName -Action $action -Principal $taskPrincipal -Settings $settings `
            -Description 'Stop the elevated mousemaster on demand (force-kill, then reload the system cursors). Fired by stop-mousemaster-admin.bat and the "mousemaster stop" Start menu entry.' `
            -Force | Out-Null
        Write-Host "  registered: $taskName"
    }

    Write-Host ''
    Write-Host '=== 3. Start menu entry "mousemaster stop" ==='
    # Same folder and style as the existing "mousemaster" entry, so PowerToys Run
    # lists both when you type "mou"; typing "stop" narrows it to this one.
    $programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $lnk = Join-Path $programs 'mousemaster stop.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $s = $shell.CreateShortcut($lnk)
    $s.TargetPath = $launcher
    $s.WorkingDirectory = $here
    if ($ShortcutOnly) { $s.Description = 'Stop mousemaster (kills the non-elevated process directly, no admin rights)' }
    else { $s.Description = 'Stop mousemaster (mousemaster-stop scheduled task, no UAC prompt)' }
    $s.WindowStyle = 7   # minimised: the launcher is silent on success
    # Red tile + dark wheel = stopped (pair of mm4-start.ico, purple tile + green wheel).
    $ico = Join-Path $here 'mm4-stop.ico'
    if (Test-Path $ico) { $s.IconLocation = "$ico,0" } else { $s.IconLocation = "$env:SystemRoot\System32\main.cpl,0" }
    $s.Save()
    if (-not (Test-Path $lnk)) { throw "Shortcut was not created: $lnk" }
    Write-Host "  created: $lnk"

    # Branch B has no Start menu entry for starting. Give it one, so "mou" works too.
    if ($ShortcutOnly) {
        $startLnk = Join-Path $programs 'mousemaster.lnk'
        $adminLnk = Join-Path $programs 'mousemaster (admin).lnk'
        $starter = Join-Path $here 'mousemaster-start.bat'
        if ((-not (Test-Path $startLnk)) -and (-not (Test-Path $adminLnk)) -and (Test-Path $starter)) {
            $st = $shell.CreateShortcut($startLnk)
            $st.TargetPath = $starter
            $st.WorkingDirectory = $here
            $st.Description = 'Start mousemaster (non-elevated)'
            $st.WindowStyle = 7
            $startIco = Join-Path $here 'mm4-start.ico'
            if (Test-Path $startIco) { $st.IconLocation = "$startIco,0" } else { $st.IconLocation = "$env:SystemRoot\System32\main.cpl,0" }
            $st.Save()
            Write-Host "  created: $startLnk  (start entry, so  mou  works as well)"
        }
    }

    Write-Host ''
    Write-Host '=== 4. Verifying ==='
    if (-not $ShortcutOnly) {
        $t = Get-ScheduledTask -TaskName $taskName
        Write-Host ("  task : {0}  state={1}  runLevel={2}" -f $t.TaskName, $t.State, $t.Principal.RunLevel)
    }
    Write-Host ("  lnk  : {0}" -f $lnk)
    Write-Host ''
    Write-Host 'DONE. From now on:'
    if ($ShortcutOnly) {
        Write-Host '  stop  : alt+e (PowerToys Run), type  stop , Enter   (or run stop-mousemaster-direct.bat)'
        Write-Host '  start : alt+e, type  mou , Enter'
        Write-Host 'No PowerToys? Press the Windows key, type  mousemaster stop , Enter. Same thing.'
    }
    else {
        Write-Host '  stop  : alt+e (PowerToys Run), type  stop , Enter   (or run stop-mousemaster-admin.bat)'
        Write-Host '  start : alt+e, type  mou , Enter                     (as before)'
    }
    Write-Host 'What the stop does: force-kills mousemaster, then reloads the system cursors.'
    Write-Host 'Log of each stop: mm-stop.log next to this script.'
    Write-Host ''
    Write-Host 'PowerToys Run may take a moment to index the new entry. If it never shows up,'
    Write-Host 'quit PowerToys from the tray and start it again.'
} catch {
    Write-Host ''
    Write-Host ("FAILED: " + $_.Exception.Message)
    Write-Host ($_.ScriptStackTrace)
} finally {
    Stop-Transcript | Out-Null
}
```

### A17. `stop-mousemaster-admin.bat` — 2.6 分岐A: UAC なしで止める（スタートメニューの「mousemaster stop」の中身）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Stop mousemaster right now, with no UAC prompt.
rem
rem  Asks the "mousemaster-stop" scheduled task to run; the task carries the
rem  elevated token, so no consent dialog appears. Requires setup-stop-task.bat
rem  to have been run once. This is what the "mousemaster stop" Start menu
rem  entry runs (alt+e in PowerToys Run, type stop, Enter).
rem
rem  Silent on success, like start-mousemaster-admin.bat. What happens is
rem  logged to mm-stop.log by the worker (stop-mousemaster-task.ps1).
rem ---------------------------------------------------------------------------
schtasks /Run /TN "mousemaster-stop" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: could not start the task "mousemaster-stop".
    echo Has setup-stop-task.bat been run?
    echo.
    pause
)
```

### A18. `stop-mousemaster-task.ps1` — 止める本体（kill → カーソル復元 → `mm-stop.log`）

```powershell
# Worker for the "mousemaster-stop" scheduled task (runs elevated, no window),
# and for stop-mousemaster-direct.bat (runs as the user, for a non-elevated
# mousemaster). Not meant to be run by hand: use stop-mousemaster-admin.bat
# (no UAC prompt), stop-mousemaster-direct.bat (no admin at all) or
# stop-mousemaster.bat (asks for UAC).
$ErrorActionPreference = 'SilentlyContinue'
$log = Join-Path $PSScriptRoot 'mm-stop.log'
function Log($msg) { ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $msg) | Add-Content -Path $log }

Log 'stop task fired'
$p = Get-Process mousemaster
if ($p) {
    # Stop-Process -Force is taskkill /F. Without force a console app ignores
    # WM_CLOSE (measured 2026-08-14), and only an elevated caller can do this.
    $ids = ($p | ForEach-Object { $_.Id }) -join ','
    $p | Stop-Process -Force
    Start-Sleep -Milliseconds 300
    if (Get-Process mousemaster) { Log "still running after kill (pid $ids)" } else { Log "killed pid $ids" }
} else {
    Log 'not running - nothing to kill'
}

# A killed mousemaster cannot put the system cursors back (render-as-cursor
# replaced them with SetSystemCursor). SPI_SETCURSORS reloads the user's cursor
# scheme. The next start would repair them as well (issue 83, 2261b7b), but a
# game may be next, so do it now.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MmCur {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
}
"@
$ok = [MmCur]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0)
Log "SPI_SETCURSORS ok=$ok"
```

### A19. `remove-stop-task.bat` — 2.6 分岐A を戻す

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Undo setup-stop-task.bat: delete the "mousemaster-stop" task and the
rem  "mousemaster stop" Start menu entry. Needs admin once (task deletion).
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

schtasks /Delete /TN "mousemaster-stop" /F
powershell -NoProfile -Command "$p = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\mousemaster stop.lnk'; if (Test-Path $p) { Remove-Item -LiteralPath $p -Force; Write-Host 'Start menu entry removed.' } else { Write-Host 'Start menu entry was not there.' }"
echo.
pause
```

### A20. `setup-stop-shortcut.bat` — 2.6 分岐B: ショートカットだけ作る（管理者権限不要）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Branch B (no admin rights): put a "mousemaster stop" entry in the Start
rem  menu that kills the NON-elevated mousemaster directly. No scheduled task,
rem  no UAC, no admin rights. Also adds a "mousemaster" start entry if there is
rem  none yet, so  mou  works in PowerToys Run as well.
rem
rem  If mousemaster runs elevated on this PC (mousemaster-admin task), use
rem  setup-stop-task.bat instead: a non-elevated stop cannot end it.
rem
rem  How to use it afterwards: alt+e (PowerToys Run), type stop, Enter.
rem  Without PowerToys: Windows key, type "mousemaster stop", Enter.
rem  Undo: delete "mousemaster stop.lnk" from the Start menu Programs folder.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-stop-task.ps1" -ShortcutOnly
echo.
pause
```

### A21. `stop-mousemaster-direct.bat` — 2.6 分岐B: 非昇格の mousemaster を直接止める

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Stop a NON-elevated mousemaster right now. No admin rights, no UAC.
rem
rem  For a PC where mousemaster runs without elevation (branch B of the
rem  setup guide: Startup shortcut autostart). Where mousemaster runs
rem  elevated (mousemaster-admin task) this cannot end it - use
rem  stop-mousemaster-admin.bat there (needs setup-stop-task.bat once).
rem
rem  Runs the same worker as the stop task, hidden: force-kill, then reload
rem  the system cursors. Logged to mm-stop.log. This is what the Start menu
rem  entry "mousemaster stop" runs after setup-stop-shortcut.bat.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0stop-mousemaster-task.ps1"
```

### A22. `set-mousemaster-icons.bat` — アイコンを貼り直す（任意。管理者権限不要）

```bat
@echo off
rem ---------------------------------------------------------------------------
rem  Re-apply the icon pair to the Start menu entries:
rem    mousemaster.lnk or mousemaster (admin).lnk : mm4-start.ico  (white mouse on purple tile, green wheel)
rem    mousemaster stop.lnk                       : mm4-stop.ico   (white mouse on red tile, wheel off)
rem  Use after re-creating either shortcut, or on another PC. No admin rights.
rem  Needs the two .ico files next to this script.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0set-mousemaster-icons.ps1"
echo.
pause
```

### A23. `set-mousemaster-icons.ps1` — A22 の本体

```powershell
# Points the two Start-menu shortcuts at the icon pair next to this script.
# Only the icon changes; target, working directory and window style are kept.
# The start entry is "mousemaster.lnk" on the home PC and "mousemaster (admin).lnk"
# where add-start-menu-shortcut.bat made it: both names are tried.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shell = New-Object -ComObject WScript.Shell
$pairs = @(
    @{ lnk = 'mousemaster.lnk';         ico = 'mm4-start.ico' },
    @{ lnk = 'mousemaster (admin).lnk'; ico = 'mm4-start.ico' },
    @{ lnk = 'mousemaster stop.lnk';    ico = 'mm4-stop.ico' }
)
$done = 0
foreach ($p in $pairs) {
    $lnkPath = Join-Path $programs $p.lnk
    $icoPath = Join-Path $here $p.ico
    if (-not (Test-Path $lnkPath)) { continue }
    if (-not (Test-Path $icoPath)) { Write-Host ("  missing icon: {0}" -f $icoPath); continue }
    $s = $shell.CreateShortcut($lnkPath)
    $s.IconLocation = "$icoPath,0"
    $s.Save()
    Write-Host ("  {0}  ->  {1}" -f $p.lnk, $p.ico)
    $done++
}
if ($done -eq 0) { Write-Host '  no mousemaster shortcut found in the Start menu Programs folder - nothing changed.' }
Write-Host ''
Write-Host 'Done. If PowerToys Run still shows the old icons, quit PowerToys from the tray and start it again.'
```

---

### A24. `check-altg-hotkey.bat` — 診断（任意）: あるキーを別のプログラムがグローバルホットキーで掴んでいないか

3.5 の「alt+g が効かない」用。何も変えない（RegisterHotKey で登録を試して即解除するだけ）。結果は画面と `altg-check.txt`。

```bat
@echo off
chcp 437 >nul
title alt+g global hotkey check
rem Finds out whether some other program holds alt+g as a global hotkey
rem (mousemaster is not involved: alt+g fails even with it stopped).
rem Nothing is changed on the PC. Result is also saved to altg-check.txt.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-altg-hotkey.ps1"
echo.
echo Result saved to altg-check.txt next to this file.
pause
```

### A25. `check-altg-hotkey.ps1` — A24 の本体

調べたいキーを増やすときは `Probe 'alt+g' $MOD_ALT 0x47` の行をコピーして仮想キーコードを変える（G=0x47、A=0x41 … Z=0x5A、数字 0x30〜0x39）。

```powershell
# Who owns alt+g?
# mousemaster was cleared on 2026-10-07: alt+g fails in OneCommander even with
# mousemaster stopped, while alt+f / alt+s work. So either another program holds
# alt+g as a GLOBAL hotkey (it swallows the key before any window sees it), or
# OneCommander itself changed. RegisterHotKey fails with error 1409 when another
# program already owns the combination. Nothing stays registered afterwards.
# Output is also saved to altg-check.txt next to this script.
$ErrorActionPreference = 'Continue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'altg-check.txt') -Force | Out-Null
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MmHotkeyProbe {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@
$MOD_ALT = 1; $MOD_CONTROL = 2; $MOD_SHIFT = 4; $MOD_WIN = 8
$script:nextId = 100
function Probe([string]$name, [uint32]$mods, [uint32]$vk) {
    $id = $script:nextId; $script:nextId++
    $ok = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, $id, $mods, $vk)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($ok) {
        [void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, $id)
        Write-Host ("  {0,-12} free    (no program holds it as a global hotkey)" -f $name)
    } elseif ($err -eq 1409) {
        Write-Host ("  {0,-12} TAKEN   (another program registered it as a global hotkey)" -f $name)
    } else {
        Write-Host ("  {0,-12} ?       (RegisterHotKey failed, error {1})" -f $name, $err)
    }
}

Write-Host ''
Write-Host ("=== alt+g check  {0:yyyy-MM-dd HH:mm:ss} ===" -f (Get-Date))
Write-Host ''
Write-Host '=== 0. Self-check (register alt+g twice: the second must fail with 1409) ==='
$a = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, 1, $MOD_ALT, 0x47)
$b = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, 2, $MOD_ALT, 0x47)
$e = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
[void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, 1)
[void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, 2)
if ($a -and -not $b -and $e -eq 1409) { Write-Host '  ok - the probe detects a taken hotkey' }
elseif (-not $a) { Write-Host '  first registration already failed - see section 1' }
else { Write-Host ("  unexpected: first={0} second={1} error={2}" -f $a, $b, $e) }

Write-Host ''
Write-Host '=== 1. Global hotkey probe (RegisterHotKey) ==='
Probe 'alt+g' $MOD_ALT 0x47
Probe 'alt+f' $MOD_ALT 0x46
Probe 'alt+s' $MOD_ALT 0x53
Probe 'alt+c' $MOD_ALT 0x43
Probe 'alt+m' $MOD_ALT 0x4D
Probe 'alt+d' $MOD_ALT 0x44
Probe 'alt+e' $MOD_ALT 0x45
Probe 'ctrl+g' $MOD_CONTROL 0x47
Probe 'win+g' $MOD_WIN 0x47

Write-Host ''
Write-Host '=== 2. OneCommander ==='
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*OneCommander*' }
if ($procs) {
    foreach ($p in $procs) {
        $path = $null; $ver = $null
        try { $path = $p.Path } catch {}
        try { $ver = $p.MainModule.FileVersionInfo.ProductVersion } catch {}
        Write-Host ("  running: {0}  pid {1}  version {2}" -f $p.ProcessName, $p.Id, $ver)
        if ($path) {
            Write-Host ("    exe: {0}" -f $path)
            $fi = Get-Item $path -ErrorAction SilentlyContinue
            if ($fi) { Write-Host ("    exe date: {0:yyyy-MM-dd HH:mm}" -f $fi.LastWriteTime) }
        } else {
            Write-Host '    exe path not readable from here (elevated process?)'
        }
    }
} else { Write-Host '  not running' }
$pkgs = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*OneCommander*' }
foreach ($k in $pkgs) {
    Write-Host ("  store package: {0}  v{1}" -f $k.Name, $k.Version)
    $d = Get-Item $k.InstallLocation -ErrorAction SilentlyContinue
    if ($d) { Write-Host ("    installed/updated: {0:yyyy-MM-dd HH:mm}  {1}" -f $d.LastWriteTime, $k.InstallLocation) }
}

Write-Host ''
Write-Host '=== 3. Programs installed or updated in the last 30 days ==='
$cut = (Get-Date).AddDays(-30)
$rows = @()
$roots = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
         'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
         'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
foreach ($r in $roots) {
    Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -and ($p.InstallDate -match '^\d{8}$')) {
            $d = $null
            try { $d = [datetime]::ParseExact($p.InstallDate, 'yyyyMMdd', $null) } catch {}
            if ($d -and $d -ge $cut) {
                $rows += [pscustomobject]@{ Date = $d; Name = $p.DisplayName; Version = $p.DisplayVersion }
            }
        }
    }
}
Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { -not $_.IsFramework } | ForEach-Object {
    $d = Get-Item $_.InstallLocation -ErrorAction SilentlyContinue
    if ($d -and $d.LastWriteTime -ge $cut) {
        $rows += [pscustomobject]@{ Date = $d.LastWriteTime; Name = ('(store) ' + $_.Name); Version = $_.Version }
    }
}
if ($rows) {
    $rows | Sort-Object Date -Descending | Select-Object -First 40 | ForEach-Object {
        Write-Host ("  {0:yyyy-MM-dd}  {1}  {2}" -f $_.Date, $_.Name, $_.Version)
    }
} else { Write-Host '  (none found)' }

Write-Host ''
Write-Host '=== 4. Running programs that are known to grab global shortcuts ==='
$suspects = 'AutoHotkey*','nvcontainer','NVIDIA*','RadeonSoftware','Discord','steam','obs64','ShareX','Greenshot',
            'Lightshot','Snagit*','lghub*','Razer*','iCUE','XMouseButtonControl','Flow.Launcher','Wox','Keypirinha',
            'Listary','Ditto','CopyQ','Everything','Clipchamp','GameBar*','EpicGamesLauncher','GalaxyClient','Dropbox',
            'TeamViewer*','AnyDesk','Parsec*','WindowsApp*','msrdc','mstsc','Bandicam*','Xbox*','QuickLook','PowerToys*'
$running = Get-Process -ErrorAction SilentlyContinue
$hits = @()
foreach ($s in $suspects) { $hits += $running | Where-Object { $_.ProcessName -like $s } }
$hits | Sort-Object ProcessName -Unique | ForEach-Object { Write-Host ("  {0}  (pid {1})" -f $_.ProcessName, $_.Id) }
if (-not $hits) { Write-Host '  (none of the usual suspects)' }

Write-Host ''
Write-Host 'Done. The same text is in altg-check.txt.'
Stop-Transcript | Out-Null
```

（付録おわり。`undo-admin-autostart.bat`（分岐Aを全部戻す）は 2026-10-14 からリポジトリにも入れた。元PC側の `mousemaster`（2026-10-24 までは `mousemaster_92`） に `fix-topmost.bat`（最前面貼り付きの解除）、`check-uiaccess.bat`（昇格の確認）もある。必要になったらユーザー経由で取り寄せる。）
