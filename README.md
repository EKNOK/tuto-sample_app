# Ruby on Rails チュートリアルのサンプルアプリケーション

これは、次の教材で作られたサンプルアプリケーションです。   
[*Ruby on Rails チュートリアル*](https://railstutorial.jp/)
[Michael Hartl](http://www.michaelhartl.com/) 著

## ライセンス

[Ruby on Rails チュートリアル](https://railstutorial.jp/)内にある
ソースコードはMITライセンスとBeerwareライセンスのもとで公開されています。
詳細は [LICENSE.md](LICENSE.md) をご覧ください。

## 使い方

このアプリケーションを動かす場合は、まずはリポジトリを手元にクローンしてください。
その後、次のコマンドで必要になる RubyGems をインストールします。

```
$ bundle install --without production
```

その後、データベースへのマイグレーションを実行します。

```
$ rails db:migrate
```

最後に、テストを実行してうまく動いているかどうか確認してください。

```
$ rails test
```

テストが無事に通ったら、Railsサーバーを立ち上げる準備が整っているはずです。

```
$ rails server
```

詳しくは、[*Ruby on Rails チュートリアル*](https://railstutorial.jp/)
を参考にしてください。


# 9章 高度なログインの仕方
SSL(secure sockets layer)  
記憶トークンのハッシュの値を保存  
remember_digest属性をaddしランダムな文字列を記憶トークンとして使う
  ->>　（例） SecureRandomモジュールにあるurlsafe_base64メソッド
attr_accessor


# 10章
## 10.30 フレンドリーフォワーディング
保護されたページにログインしていないユーザーがアクセスした際、ログインしたあとのリダイレクト先は、ユーザーが開こうとしていたページにしてあげるのが優しい..  
ユーザーが希望のページに転送するには、リクエスト時点のページをどこかに保存しておく必要がある  
store_location, redirect_back_orメソッドを使い作る  
なお、これらのメソッドはSessionsヘルパーで定義する。  
(app/helpers/sessions_helper.rb)

# 11章
新規登録したユーザーが本当にそのメールアドレスの持ち主なのかどうか確認  
(1) 有効化トークンやダイジェストを関連付けた状態で  
(2) 有効化トークンを含めたリンクをユーザーにメールで送信し、  
(3) ユーザーがそのリンクをクリックすると有効化できるようにする  
また、12章でもパスワードを再設定できる仕組みを実装する  

*段取り/手順*

1. ユーザーの初期状態は「有効化されていない」(unactivated)にしておく
2. ユーザー登録が行われた際、有効かトークンと、それに対する有効化ダイジェストを作成する。
3. 有効化ダイジェストはデータベースを保存しておき、有効化トークンはメールアドレスと一緒に、ユーザーに送信する有効化用メールのリンクに仕込んでおく。
4. ユーザーがメールのリンクをクリックしたら、アプリケーションはメールアドレスをキーにしてユーザーを探し、データベース内に保存しておいた有効化ダイジェストと比較することでトークンを認証する。
5. ユーザーを認証できたら、ユーザーのステータスを「有効化されていない」から「有効化済み」(activated)に変更する。
## 11.1 アカウントの有効化
AccountActivationsコントローラを作成。  
account_activaationsのeditアクションのルーティングを用意。  
usersモデルに、 activation_digest, activated, activated_at のカラムを追加  
ユーザーが新しい登録を完了するためには必ずアカウントの有効化は必要になるから、  
有効化トークンや有効化ダイジェストはユーザーオブジェクトが作成される前に作成しておく必要がある  
model/user.rbに create_activation_digestメソッドをprivate内に作成  

```
def create_activation_digest
  self.activation_token  = User.new_token
  self.activation_digest = User.digest(activation_token)
end
```

リスト9.3のrememberメソッドと比べる

```
# 永続セッションのためにユーザーをデータベースに記憶する
def remember
  self.remember_token = User.new_token
  update_attribute(:remember_digest, User.digest(remember_token))
end
```

ここでの本質的な構造は同じなのでrememberメソッドを使い回す  
二つの主な違いは、後者の update_attribute の使い方で  
(記憶トークンやダイジェストはすでにデータベースにいるユーザーのために作成されるのに対し、before_create コールバックの方はユーザーが作成される前に呼び出される。  
このコールバックがあることによって User.new で新しいユーザーが定義されると activation_token属性やactivation_digest属性が得られるようになる)
後者の activation_digest属性はすでにデータベースのカラムとの関連付けが出来上がっているので、ユーザーが保存されるときに一緒に保存される

## 11.2 アカウント有効化のメール送信
データのモデル化が終わったので、次にアカウント有効化メールの送信に必要なコードを追加する。  
このメソッドではAction Mailerライブラリを使ってUserのメイラーを追加  
このメイラーはUserコントローラの構成はコントローラのアクションと似ている

*メイラーの作成*  (viewに作成される)

```$ rails g mailer UserMailer account_activation password_reset

```

今回必要となる`acount_activation`メソッドと12章で必要となる`password_reset`メソッドを自動生成  
生成したメイラーごとに、ビューのテンプレートが2つずつ生成
* テキスト用のテンプレート(`app/views/user_mailer/account_activation.text.erb`)
* HTMLメール用のテンプレート(`app/views/user_mailer/account_activation.html.erb`)
HTML用のメールを拒否している又対応していない場合があるため  
  `app/mailers/application_mailer.rb` 生成されたApplicationメイラー
  `app/mailers/user_mailer.rb` 生成されたUserメイラー
Applicationメイラーでデフォルトとなるform(差出人)、layoutを設定  
Userメイラーでインスタンス変数や宛先 mail to: _FULLIN_ を設定

## 11.2.2 送信メールのプレビュー
ビューのテンプレートの実際の表示を簡単に認識するために、メールプレビューという裏技がある  
特殊なURLにアクセスするとメールのメッセージをその場でプレビューでき、実際に送信しなくても確認できる  
`config/environments/development.rb` で編集  
`test/mailers/previews/user_mailer_preview.rb` Userメイラープレビュー  
自動生成のままじゃ動かないので`account_activation`の引数には有効なuserオブジェクトを渡す必要あり  
```
# localhost:3000/rails/mailers/user_mailer/account_activation にアクセス
def account_activation
  user = User.first
  user.activation_token = User.new_token
  UserMailer.account_activation(user)
end
```
`user.activation_token`の値にはアカウント有効化のトークンが必要なので、代入の省力はできないが`activation_token`は仮の属性でしかないので、データベースのユーザーはこの値は実際には持っていない  

## 11.2.3 送信メールのテスト
このメールプレビューのテストも作成して、プレビューをダブルチェックできるようにする  
`test/mailers/user_mailer_test.rb` Userメイラーのテスト(自動生成)
  
