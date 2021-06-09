# Ruby on Rails 6 で 郵便番号住所検索 な gem

## JpAddressとは
日本郵便の「[郵便番号データ](https://www.post.japanpost.jp/zipcode/dl/oogaki-zip.html)」を Rails 6.1 で使用するための gem です。
以下の機能を提供します。

* [[郵便番号データ](https://www.post.japanpost.jp/zipcode/dl/oogaki/zip/ken_all.zip "ken_all.zip")]をダウンロードして自前ＤＢのテーブル（jp_address_zipcodes）にロードするクラスメソッド。（```JpAddress::Zipcode.load_master_data```）
* 郵便番号を受け取り都道府県名と住所をJSONで返却するAPI。
（```jp_address/zipcodes#search```）

要するに、「**郵便番号住所検索 ruby gem**」でググった人向けの gem です。

APIはお使いのRailsアプリケーションにマウントして使います。外部のサービスに依存しません。<br>
あと必要なのは、戻ってくるJSONを加工してHTML要素にセットするJavaScriptの記述だけです。<br>
（本記事下部にサンプルコードを掲載しています。）

### インストール
GemFileに追記
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

環境にもよりますが、１～３分ぐらいかかると思います。

※ APP_ROOT/tmp/ を作業ディレクトリに使用しています。<br>
※ 最初にテーブルをトランケートしますので、毎回「全件insert」になります。

### APIのマウント
Railsアプリの config/routes.rb に追記。
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

### APIを利用するサンプル JavaScript
フォームに
1. #zipcode （郵便番号を入力するテキストボックス）
2. #prefecture_id （いわゆる都道府県プルダウン）
3. #address （住所を表示するテキストボックス）

の３要素があるとします。<br>
#zipcodeに入れられた値を keyup イベントで拾ってAPIを叩き、都道府県プルダウンを選択し、住所をセットするサンプルです。

都道府県プルダウンは、戻ってくるJSONの "prefecture" すなわち都道府県名で選択します。<br>
ですので、お持ちの都道府県マスターの各レコードがどのようなＩＤを持っていても構いません。

※ JQuery の存在を前提にしています。<br>
※ 郵便番号の半角ハイフンは自動でカットされます。<br>
※ もともと CoffeeScript で書いてあったソースを decaffeinate したものですので冗長です。本質的な処理はAddressSearch が担っているだけで、他の関数は decaffeinate に必要なだけです。

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

#### application.js など共通に読み込まれるファイルに配置するJavaScript

```js script
  function _classCallCheck(instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  }

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;

      if ("value" in descriptor)
        descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps)
      _defineProperties(Constructor.prototype, protoProps);
    if (staticProps)
      _defineProperties(Constructor, staticProps);
    return Constructor;
  }

  var AddressSearch = function() {
    "use strict";
    function AddressSearch(zip_elem_id, prefecture_elem_id, address_elem_id) {
      _classCallCheck(this, AddressSearch);
      this.zip                = $(zip_elem_id);
      this.prefecture         = $(prefecture_elem_id);
      this.address            = $(address_elem_id);
      this.prefecture_elem_id = prefecture_elem_id;
    }

    _createClass(AddressSearch, [{
      key: "_remove_hyphen",
      value: function _remove_hyphen() {
        return this.zip.val(this.zip.val().replace(/-/, ''));
      }
    }, {
      key: "_clear_current_value",
      value: function _clear_current_value() {
        $(this.prefecture_elem_id + ' >option:eq(0)').prop('selected', true);
        return this.address.val('');
      }
    }, {
      key: "_set_prefecture",
      value: function _set_prefecture(json) {
        return $(this.prefecture_elem_id + ' > option').each(function() {
          if ($(this).text() === json['prefecture']) {
            return $(this).prop('selected', true);
          }
        });
      }
    }, {
      key: "_set_address",
      value: function _set_address(json) {
        return this.address.val(json['city'] + json['town']);
      }
    }, {
      key: "_call_api",
      value: function _call_api() {
        var _this = this;
        return $.getJSON('/jp_address/zipcodes/search', {zip: this.zip.val()}, function(json) {
          if (json['id'] === null) {
            return _this._clear_current_value();
          } else {
            _this._set_prefecture(json);
            return _this._set_address(json);
          }
        });
      }
    }, {
      key: "execute",
      value: function execute() {
        this._remove_hyphen();
        if (this.zip.val().length === 7) {
          return this._call_api();
        }
      }
    }]);

    return AddressSearch;
  }();
```

#### フォームのあるページに配置するJavaScript
```js script
  // #zipcode, #prefecture_id, #address を各自の環境に合わせて書き換えてください。
  $(function() {
    var address_search = new AddressSearch('#zipcode', '#prefecture_id', '#address');
    $('#zipcode').keyup(function() {
      address_search.execute();
    });
  });
```

##### 作者
Copyright 2016 (c) Tad Kam, under MIT License.<br>
Tad Kam <densya203@skult.jp>
