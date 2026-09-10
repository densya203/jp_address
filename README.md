# Ruby on Rails で 郵便番号住所検索 な gem

## JpAddressとは
日本郵便の「[郵便番号データ](https://www.post.japanpost.jp/zipcode/download.html)」を用いて、あなたの Rails サイトに「郵便番号からの住所検索機能」を組み込むための gem です。
以下の機能を提供します。

* [[郵便番号データ](https://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip "ken_all.zip")]をダウンロードして自前ＤＢのテーブル（jp_address_zipcodes）にロードするクラスメソッド。（```JpAddress::Zipcode.load_master_data```）
* 郵便番号を受け取り都道府県名と住所をJSONで返却するAPI。
（```jp_address/zipcodes#search```）

要するに、「**郵便番号住所検索 ruby gem**」でググった人向けの gem です。

APIはお使いのRailsアプリケーションにマウントして使います。外部のサービスに依存しません。<br>
あと必要なのは、戻ってくるJSONを加工してHTML要素にセットするJavaScriptの記述だけです。<br>
（本記事下部にサンプルコードを掲載しています。）

### 対応バージョン

| | 対応 |
|---|---|
| Ruby | 3.1 以降 |
| Rails | 7.1 / 8.0 / 8.1 |

Rails 6.x 以前をお使いの場合は 1.0.2 をご利用ください。

### インストール
Gemfileに追記
```ruby
gem 'jp_address'
  ```

### テーブル（jp_address_zipcodes）の作成
 ```
$ bundle 
$ bundle exec rails jp_address:install:migrations
$ bundle exec rails db:migrate
```

### テーブルへの郵便番号データのロード
```
# 開発環境
$ bundle exec rails runner -e development 'JpAddress::Zipcode.load_master_data'

# 本番環境
$ bundle exec rails runner -e production 'JpAddress::Zipcode.load_master_data'
```

APP_ROOT/tmp/ を作業ディレクトリに使用しています。<br>
最初にテーブルをトランケートしますので、毎回「全件insert」になります。<br>

すでに手元に ken_all.csv がある場合は、パスを渡せばダウンロードを省略できます。<br>
（文字コードは日本郵便の配布どおり CP932 のままで構いません。）
```ruby
JpAddress::Zipcode.load_master_data('tmp/ken_all.csv')
```

同じ郵便番号を持つレコードは統合されます。<br>
<br>
例：9896712<br>
```
"宮城県","大崎市","鳴子温泉水沼"
"宮城県","大崎市","鳴子温泉南山"
"宮城県","大崎市","鳴子温泉山際"
"宮城県","大崎市","鳴子温泉和田"
```
これらは先頭から共通する地名を探し、うまく見つかれば
```
"宮城県","大崎市","鳴子温泉"
```
として１つのレコードにします。
共通する地名が抜き出せない場合は空の町名にします。

### APIのマウント
Railsアプリの config/routes.rb に追記。
at: に渡す値は /jp_address でなくても /service や /api などでも構いません。
```ruby
mount JpAddress::Engine, at: "/jp_address"
```

### APIの利用
/jp_address にマウントした場合、下記URLへGETリクエストをすることで、JSONを取得できます。<br>
後はこれを好きに加工してテキストボックスなどにセットして使ってください。

**get リクエスト先**
```
http://localhost:3000/jp_address/zipcodes/search?zip=5330033
```

**API が返す JSON**
```js script
{"id":84280,"zip":"5330033","prefecture":"大阪府","city":"大阪市東淀川区","town":"東中島"}
```

該当する郵便番号がない場合は、各項目が null の JSON が返ります。
```js script
{"id":null,"zip":null,"prefecture":null,"city":null,"town":null}
```

半角ハイフン・空白・全角数字は自動的に取り除かれるので、`533-0033` や `５３３－００３３` を
そのまま投げても構いません。

### APIを利用するサンプル JavaScript
フォームに
1. #zipcode （郵便番号を入力するテキストボックス）
2. #prefecture_id （いわゆる都道府県プルダウン）
3. #address （住所を表示するテキストボックス）

の３要素があるとします。<br>
#zipcodeに入れられた値を input イベントで拾ってAPIを叩き、都道府県プルダウンを選択し、住所をセットするサンプルです。<br>

都道府県プルダウンは、戻ってくるJSONの "prefecture" すなわち都道府県名で選択します。<br>
ですので、お持ちの都道府県マスターの各レコードがどのようなＩＤを持っていても構いません。

#### フォーム
```
<form>
  <input type="text" name="zipcode" id="zipcode">
  <select name="prefecture_id" id="prefecture_id">
    <option value="1">北海道</option>
    <option value="2">青森県</option>
    <option value="3">岩手県</option>
    <option value="4">宮城県</option>
    <option value="5">秋田県</option>
    <option value="6">山形県</option>
    <option value="7">福島県</option>
    <option value="8">東京都</option>
    <option value="9">神奈川県</option>
    <option value="10">埼玉県</option>
    <option value="11">千葉県</option>
    <option value="12">茨城県</option>
    <option value="13">栃木県</option>
    <option value="14">群馬県</option>
    <option value="15">山梨県</option>
    <option value="16">新潟県</option>
    <option value="17">長野県</option>
    <option value="18">富山県</option>
    <option value="19">石川県</option>
    <option value="20">福井県</option>
    <option value="21">愛知県</option>
    <option value="22">岐阜県</option>
    <option value="23">静岡県</option>
    <option value="24">三重県</option>
    <option value="25">大阪府</option>
    <option value="26">兵庫県</option>
    <option value="27">京都府</option>
    <option value="28">滋賀県</option>
    <option value="29">奈良県</option>
    <option value="30">和歌山県</option>
    <option value="31">鳥取県</option>
    <option value="32">島根県</option>
    <option value="33">岡山県</option>
    <option value="34">広島県</option>
    <option value="35">山口県</option>
    <option value="36">徳島県</option>
    <option value="37">香川県</option>
    <option value="38">愛媛県</option>
    <option value="39">高知県</option>
    <option value="40">福岡県</option>
    <option value="41">佐賀県</option>
    <option value="42">長崎県</option>
    <option value="43">熊本県</option>
    <option value="44">大分県</option>
    <option value="45">宮崎県</option>
    <option value="46">鹿児島県</option>
    <option value="47">沖縄県</option>
  </select>
  <input type="text" name="address" id="address">
</form>
```

#### JavaScript
jQuery などのライブラリは不要です。app/javascript 配下など、フォームのあるページで
読み込まれる場所に置いてください。

```js script
class AddressSearch {
  constructor(zipSelector, prefectureSelector, addressSelector, endpoint = '/jp_address/zipcodes/search') {
    this.zip        = document.querySelector(zipSelector);
    this.prefecture = document.querySelector(prefectureSelector);
    this.address    = document.querySelector(addressSelector);
    this.endpoint   = endpoint;
  }

  start() {
    this.zip.addEventListener('input', () => this.execute());
  }

  async execute() {
    const zip = this.zip.value.replace(/[^0-9０-９]/g, '');
    if (zip.length !== 7) return;

    const url = `${this.endpoint}?zip=${encodeURIComponent(zip)}`;
    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!res.ok) return;

    const json = await res.json();
    if (json.id === null) {
      this.clear();
    } else {
      this.setPrefecture(json.prefecture);
      this.address.value = `${json.city}${json.town}`;
    }
  }

  clear() {
    this.prefecture.selectedIndex = 0;
    this.address.value = '';
  }

  setPrefecture(name) {
    for (const option of this.prefecture.options) {
      if (option.text === name) {
        option.selected = true;
        return;
      }
    }
  }
}

// #zipcode, #prefecture_id, #address を各自の環境に合わせて書き換えてください。
document.addEventListener('DOMContentLoaded', () => {
  new AddressSearch('#zipcode', '#prefecture_id', '#address').start();
});
```

### 開発

```
$ bundle install
$ bundle exec rspec
```

複数バージョンの Rails で試す場合は gemfiles/ 配下の Gemfile を使ってください。

```
$ BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle install
$ BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rspec
```

##### 作者
Copyright 2016 (c) Tad Kam, under MIT License.<br>
Tad Kam <densya203@skult.jp>
