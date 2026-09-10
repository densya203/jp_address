# CHANGELOG

## 2.0.0

最新の Ruby / Rails への対応と、郵便番号データの取り込みまわりのバグ修正。

### 対応バージョン

* Ruby 3.1 〜 3.4、Rails 7.1 / 8.0 / 8.1 に対応。
  （Ruby 3.1 + Rails 7.1 〜 Ruby 3.4 + Rails 8.1 で実際にテスト済み）
* Rails 6.x 以前のサポートを終了。
* Ruby 3.4 で `csv` が bundled gem になったため、gemspec の依存に追加。
  これがないと `require 'csv'` に失敗する。
* `railties` / `activerecord` を runtime 依存として明示。
* rubyzip 3.x に対応（`>= 2.3, < 4.0`）。

### バグ修正

* **町域名が複数行に分かれている郵便番号で町名が消えていた**。
  ken_all.csv は町域名が長いと括弧の途中で改行して次の行に続くが、その
  継続行を別の町名として扱っていたため、共通部分が見つからず町名が空に
  なっていた。括弧が閉じるまでの行を読み飛ばすようにした。
  例：9292225（石川県羽咋郡宝達志水町 米出）が `""` → `"米出"`。
* **同じ郵便番号の行が全部同じ町名でも町名が空になっていた**。
  `_find_shared_name_from` が「差分が見つからない＝共通部分なし」と
  判定していたのを修正。短い方の地名がまるごと共通部分になる場合
  （例：東中島／東中島本町）もその地名を返すようにした。
* 日本郵便へのリクエストがリダイレクト・エラーレスポンスを一切見ていな
  かったのを修正。リダイレクトは最大 5 回まで追い、200 以外は
  `JpAddress::Zipcode::DownloadError` を投げる。
* zip の中から CSV エントリだけを取り出すようにした（従来は全エントリを
  同じパスに展開しようとしていた）。
* 存在しない CSV パスを `load_master_data` に渡すと、無駄にダウンロード
  してから `Errno::ENOENT` になっていたのを `ArgumentError` に。
* `row[8]` が空の行で `NoMethodError` にならないようにした。
* `FileUtils` を require していなかったのを修正。

### 変更

* `load_master_data` を全面的に書き直し。行ごとの生 SQL を `insert_all!`
  でのバッチ投入に変え、統合処理も CSV 読み込み中にメモリ上で行うように
  したので、大幅に速くなった（本番でのロードが数分 → 数十秒程度）。
  これに伴い内部メソッド `_merge_same_zip_addresses` は削除。
* API のレスポンスを `render plain:` から `render json:` に変更。
  Content-Type が `text/plain` から `application/json` になる。
* 郵便番号の全角数字（`５３３－００３３`）を受け付けるようにした。
* `JpAddress::ApplicationRecord` を追加し、`Zipcode` の親クラスにした。
* Sprockets 前提の app/assets・レイアウト・空の ApplicationHelper を削除。
  JSON しか返さない engine には不要で、propshaft / importmap 環境では
  むしろ壊れるため。
* テストを VCR カセット（2.5MB のバイナリ）から WebMock のスタブに置き換え。
  コントローラスペックはリクエストスペックに変更。
* GitHub Actions で Ruby × Rails のマトリクステストを追加。

## 1.0.2 以前

省略。
