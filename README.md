# mousemaster-config

*Personal configuration for [mousemaster](https://github.com/petoncle/mousemaster) on Windows 11 with a Japanese (JIS) keyboard, plus the batch/PowerShell scripts around it. Notes are in Japanese. Use at your own risk.*

個人PCで使っている [mousemaster](https://github.com/petoncle/mousemaster) の本番設定一式。
別のPC（会社PC）に同じ構成を持ち込むための置き場で、中身は `PLAN-company-pc-migration.md` の
1a / 1b 節「何を運ぶか」と同じ。

## 入っているもの

| ファイル | 何か |
|---|---|
| `mousemaster.properties` | 本番設定。先頭のヘッダに変更履歴と「なぜそうしたか」が全部ある |
| `PLAN-company-pc-migration.md` | 持ち込み手順書。持ち込み先の Claude に読ませる前提で書いてある |
| `*.bat` / `*.ps1`（25 本） | 起動・自動起動・即停止・カーソル復旧・診断の運用スクリプト（PLAN 付録A と同一） |
| `snipaste-unpin.ahk` + `install-/remove-snipaste-unpin.bat` | 任意。Snipaste のピンを古い順に閉じる AutoHotkey v2 の常駐（mousemaster の Shift+Z → F14 で発火）。Snipaste と AutoHotkey v2 を入れている時だけ |
| `cursors/` | 待機カーソルの差し替え（任意。見た目だけ） |
| `mm4-start.ico` / `mm4-stop.ico` | スタートメニューの「mousemaster」「mousemaster stop」用アイコン（任意） |
| `SHA256SUMS.txt` | 全ファイルの sha256。`mousemaster.exe` の分も先頭にある |
| `.gitattributes` | `* -text`。改行を変換しない（`.bat`/`.ps1` は CRLF のまま、`.properties` は LF のまま）。これが無いと Windows の git が `.bat` を LF で保存し、Download ZIP の `.bat` が壊れる |

## 入っていないもの

- **`mousemaster.exe`** … 大きい（約 82 MB）ので git には入れず **Releases** に添付する。
  作者の nightly ビルドそのもの（どのコミットかは Release のタグ名と `SHA256SUMS.txt` に書く）。
- ログ、`.bak`、写真、個人PC側の作業メモ（CLAUDE.md / LOG.md）、テストハーネス（作者のソースを含むため）。
- マシン名・ユーザー名・メールアドレスなどの機微情報は入れない方針（Public リポジトリ）。入れる前に `sync-github-export.py` が走査する。

## 持ち込み先のPCでの取り方

1. このページの **Code → Download ZIP** で落として、`Downloads\mousemaster_92` に展開する
   （フォルダ名は PLAN の手順がそう書いてあるため。中のスクリプトは相対名で呼び合うので同じフォルダに置く）。
2. **Releases** から `mousemaster.exe` を落として同じフォルダに置く。
3. PowerShell でハッシュを照合する（管理者権限不要）。`.bat` が LF になっていないかもこれで分かる（`SHA256SUMS.txt` は CRLF のファイルから計算してある）:
   ```powershell
   Get-FileHash -Algorithm SHA256 .\mousemaster.exe, .\mousemaster.properties | Format-List Path, Hash
   ```
   `SHA256SUMS.txt` と一致しなければ運搬で壊れている。使わない。
4. その PC の Claude に `PLAN-company-pc-migration.md` を読ませて、書いてある順に進める。

## 更新の仕方（個人PC側）

1. Cowork の VM で `python3 sync-github-export.py`（`mousemaster_92` 直下）を実行して `github-export/` を作り直す。
2. `github-export\publish.bat` を実行する（変更をコミットして push。初回はリポジトリを作ってから）。
3. exe を差し替えた時は Releases に新しいタグで添付し直す。
