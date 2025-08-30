# Photozousan

[フォト蔵](http://photozou.jp/) のアルバムにアップロードした写真を一括で取得するためのgemです。

現在、[フォト蔵](http://photozou.jp/) にアルバムの写真を一括ダウンロードする機能がないため作成しました。
[フォト蔵API](http://photozou.jp/basic/api)を使用しており、gem利用時にはフォト蔵アカウントが必要となります。

## Installation

    $ gem build photozousan.gemspec
    $ gem install photozousan-x.x.x

## Usage

### コマンドライン引数を使用する方法（推奨）

```bash
# bin/photozousanコマンドを使用する場合
$ photozousan -i "your-email@example.com" -p "your-password" -a 12345 -l 100

# または、直接rubyファイルを実行する場合
$ ruby lib/photozousan.rb -i "your-email@example.com" -p "your-password" -a 12345 -l 100

# 短縮形
$ photozousan -i "your-email@example.com" -p "your-password" -a 12345 -l 100

# 長い形式
$ photozousan --id "your-email@example.com" --password "your-password" --album 12345 --limit 100

# ヘルプを表示
$ photozousan -h

# バージョンを表示
$ photozousan -v
```

#### オプション一覧

- `-i, --id ID`: PhotoZouのユーザーID（メールアドレス）
- `-p, --password PASSWORD`: PhotoZouのパスワード
- `-a, --album ALBUM_ID`: ダウンロードするアルバムID
- `-l, --limit LIMIT`: ダウンロードする写真の上限数（1-1000）
- `-h, --help`: ヘルプメッセージを表示
- `-v, --version`: バージョン情報を表示

### 対話的に入力する方法（従来の方法）

```bash
$ ruby lib/photozousan.rb
```

* donwload photozou-album id?: アルバムIDを入力します。フォト蔵アルバムページURL末尾の数値がアルバムURLとなります。

    http://photozou.jp/photo/list/[ユーザーID]/[アルバムID]
* donwload image limit?(1-1000): 1度にダウンロードする写真ファイルの上限を設定します。奨励値は100です。
* your photozou id?: あなたのフォト蔵ID（メールアドレス）(注：フォト蔵のURLに含まれるID**ではありません**)
* your photozou password?: あなたのフォト蔵パスワード
（Twitter/Facebookアカウントでユーザー登録している場合、マイページの「設定」からパスワードを設定する必要があります。）

## 注意事項

- ユーザーIDはフォト蔵のURLに含まれるIDではなく、**メールアドレス**です
- パスワードは平文でコマンドラインに表示されるため、履歴に残らないよう注意してください
- アルバムIDはフォト蔵のアルバムページURLの末尾の数値です

## 出力

コマンドを実行したディレクトリに以下の形式のフォルダが作成され、全ての写真はそのフォルダにダウンロードされます：

- **アルバムIDを指定した場合**: `Original_[アルバムID]_[ダウンロード時刻]`
  - 例: `Original_663920_20250127143022`
- **アルバムIDを指定しない場合**: `Original_[ダウンロード時刻]`
  - 例: `Original_20250127143022`

フォルダ名には以下の情報が含まれます：
- `Original`: 固定プレフィックス
- `[アルバムID]`: ダウンロードしたアルバムのID（指定した場合のみ）
- `[ダウンロード時刻]`: ダウンロード開始時刻（YYYYMMDDHHMMSS形式）

### アルバム情報ファイル

ダウンロードフォルダには、以下の2つのファイルが自動的に作成されます：

#### `album_info.json`
アルバムの詳細情報をJSON形式で保存します。以下の情報が含まれます：
- アルバム名、説明
- アルバムID、ユーザーID
- 写真数、作成日時、更新日時
- 権限設定、著作権情報
- カバー写真ID、公開メッセージ
- アップロード用メールアドレス

#### `album_info.md`
アルバムの詳細情報をMarkdown形式で保存します。以下のセクションで構成されています：
- **アルバム名**: 見出し1で表示
- **説明**: アルバムの説明文（ある場合）
- **基本情報**: テーブル形式で詳細情報を表示
- **カバー写真**: カバー写真ID（ある場合）
- **公開メッセージ**: 公開設定のメッセージ（ある場合）
- **アップロード情報**: アップロード用メールアドレス（ある場合）

これらのファイルにより、ダウンロードした写真の詳細な背景情報を確認できます。

## Contributing

1. Fork it ( https://github.com/irasally/photozousan/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Reques
