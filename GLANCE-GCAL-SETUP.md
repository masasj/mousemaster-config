# glance と Google カレンダーをつなぐ手順（自宅 PC、1 回だけ）

`w` で出る小窓（glance.ahk）に Google カレンダーの予定を出し、小窓で打ったメモを Google の予定にする。
Google 側で「自分専用の OAuth クライアント」を 1 つ作って、トークンを PC のファイルに置く作り。
**client / token のファイルは秘密。GitHub（github-export）には入れない**（sync-github-export.py は
明示したファイルしかコピーしないので、置き場所を守れば入らない。`.gitignore` にも書いてある）。

## 1. Google Cloud Console でプロジェクトと OAuth クライアントを作る（10 分）

1. https://console.cloud.google.com/ を開く（普段の Google アカウントで）。
2. 上のプロジェクト選択 → 「新しいプロジェクト」→ 名前 `glance` → 作成 → そのプロジェクトを選ぶ。
3. 左メニュー「API とサービス」→「ライブラリ」→ `Google Calendar API` を検索 → 「有効にする」。
4. 「API とサービス」→「OAuth 同意画面」（新しい画面では「Google Auth Platform」→「ブランディング」）:
   - ユーザーの種類: **外部**、アプリ名 `glance`、ユーザー サポートメールと連絡先メールに自分のアドレス → 保存。
   - 「対象」（Audience）の **公開ステータスを「本番環境」にする**（「アプリを公開」）。
     テスト状態のままだと、取ったトークンが 7 日で切れて `auth` のやり直しになる。
     審査は不要（自分しか使わない）。代わりに許可画面で「このアプリは Google で確認されていません」
     と出るが、「詳細」→「glance（安全ではないページ）に移動」で進めばよい。
5. 「認証情報」→「認証情報を作成」→「OAuth クライアント ID」→ アプリケーションの種類 **デスクトップ アプリ**、
   名前 `glance` → 作成 → **JSON をダウンロード**。
6. ダウンロードした `client_secret_….json` を `mousemaster_92\glance-gcal-client.json` という名前で置く。

## 2. トークンを取る

`mousemaster_92` で PowerShell を開いて:

```
powershell -ExecutionPolicy Bypass -File .\glance-gcal.ps1 auth
```

ブラウザが開く → アカウントを選ぶ → （未確認の警告が出たら「詳細」→ 移動）→ カレンダーの権限を許可 →
ブラウザに `glance: connected.` と出れば完了。`glance-gcal-token.json` ができている。

確認:

```
powershell -ExecutionPolicy Bypass -File .\glance-gcal.ps1 list 2026-10
```

今月の予定が `日付<TAB>時刻<TAB>件名<TAB>ID` で出る（終日は時刻が空）。

## 3. glance を再起動

`glance.ahk` をダブルクリック（か `install-glance.bat`）。起動時に `glance-gcal-token.json` があれば Google モードになり、
小窓の一番下に `Google Calendar` と出る。小窓を開くたびに裏で今月を取り直す（開いた瞬間は前回の内容、
数秒後に更新。下に `Google: 13:05 2026-10` のように出る）。

- 日をクリック → `歯医者` + Enter → 終日の予定
- `14:00 歯医者` + Enter → 14:00 から 1 時間、`14:00-15:30 歯医者` → 終了も指定
- 予定をダブルクリック → 削除（Google 側も消える。確認は出ないので注意）

## 困った時

- `glance-gcal.log` にエラーが出る。`invalid_grant` ならトークン切れ: `auth` をやり直す
  （手順 1-4 の「本番環境」になっていれば切れない）。
- やり直す時は https://myaccount.google.com/permissions で glance のアクセス権を削除してから `auth`。
