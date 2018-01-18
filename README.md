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

# 11章 アカウントの有効化
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
## 11.1 AccountActivationsリソース
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

```
$ rails g mailer UserMailer account_activation password_reset
```

今回必要となる`acount_activation`メソッドと12章で必要となる`password_reset`メソッドを自動生成  
生成したメイラーごとに、ビューのテンプレートが2つずつ生成
* テキスト用のテンプレート(`app/views/user_mailer/account_activation.text.erb`)
* HTMLメール用のテンプレート(`app/views/user_mailer/account_activation.html.erb`)
HTML用のメールを拒否している又対応していない場合があるため  
  `app/mailers/application_mailer.rb` 生成されたApplicationメイラー
  `app/mailers/user_mailer.rb` 生成されたUserメイラー
Applicationメイラーでデフォルトとなるform(差出人)、layoutを設定  
Userメイラーでインスタンス変数や宛先 mail to: _FULL_IN_ を設定

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
`CGI.eascape(user.email)`を使えば、テスト用のユーザーのメールアドレスをエスケープすることもできる
`config/environments/test.rb`(テストのドメインホストを設定する)
` config.action_mailer.default_url_options = { host: 'example.com' }`を追加するをテストがスイートされる  

## 11.2.4 ユーザーのcreateアクションを更新
あとはユーザー登録を行うcreateアクションに数行追加するだけでメイラーをアプリケーションで実際に使うことができる  
`app/controllers/users_controller.rb`  ユーザー登録にアカウント有効化を追加する  
アクションの内容
* 登録されたメールにメールを送る
* リダイレクト先をルートURLに変更
`test/integration/users_signup_test.rb` 失敗するテストを一時的にコメントアウトにする

## 11.3 アカウントを有効化する
今度はAccountActivationsコントローラのeditアクションを書いていく  
又、アクションへのテストを書き、しっかりテストできていることができたら、AccountActivationsコントローラからUserモデルにコードを移していく作業(リファクタリング)にも取り掛かっていく  
## 11.3.1 authenticated?メソッドの抽象化
有効化トークンとメールをそれぞれ`params[:id]`と`params[:email]`で参照できることを思い出すと、パスワードので守ると記憶トークンで学んだことを元に、次のようなコードでユーザーを検索して認証することにする
```
user = User.find_by(email: params[:email])
if user && user.authenticated?(:activation, params[:id])
```

ここで使っている`authenticated?`メソッドは、アカウント有効化のダイジェストと、渡されたトークンが一致するかどうかをチェックする。ただし、このメソッドは記憶トークン用なので今は正常に動作しない。ので、
```
# トークンがダイジェストと一致したらtrueを返す
def authenticated?(remember_token)
  return false if remember_digest.nil?
  BCrypt::Password.new(remember_digest).is_password?(remember_token)
end
```
`remember_digest`はUserモデルも属性なので、を書き換える。  
今回は、上のコードのrememberの部分をどうにかして編すとして扱いたい。  
つまり状況に応じて呼び出すメソッドを切り替えたい。  
`self.FOOBAR_digest`
これから実装する`authenticated?`メソッドでは、受けとったパラメータに応じて呼び出すメソッドを切り替えるて法を使う。  
この手法を「***メタプログラミング***」を呼ばれる。  
簡単にいうと、「プログラムでプログラムを作成する。」  
ここで重要なのは`send`メソッドの強力極まる機能。  
このメソッドは、渡されたオブジェクトに「メッセージを送る」ことによって、呼び出されたメソッドを動的に決めることができる。  (例) ->  
```
>> user = User.first
>> user.activation_digest
=> "$2a$10$4e6TFzEJAVNyjLv8Q5u22ensMt28qEkx0roaZvtRcp6UZKRM6N9Ae"
>> user.send(:activation_digest)
=> "$2a$10$4e6TFzEJAVNyjLv8Q5u22ensMt28qEkx0roaZvtRcp6UZKRM6N9Ae"
>> user.send("activation_digest")
=> "$2a$10$4e6TFzEJAVNyjLv8Q5u22ensMt28qEkx0roaZvtRcp6UZKRM6N9Ae"
>> attribute = :activation
>> user.send("#{attribute}_digest")
=> "$2a$10$4e6TFzEJAVNyjLv8Q5u22ensMt28qEkx0roaZvtRcp6UZKRM6N9Ae"
```
シンボル`:activation`と等しい`attribute`変数を定義して、文字列の式展開(interpolation)を使って引数を正しく組み立ててから、`send`に渡している。文字列`activation`でも同じことができるが、Ruby的にはシンボル  
`#{attribute}_digest`  
シンボル文字列どちら使っても、上のコードは、  
`activation_digest`  

`send`メソッドの動作原理がわかったので、この仕組みを利用して`authenticated?`メソッドを書き換えてみる。  
`model/user.rb`
```
def authenticated?(attribute, token)
  #文字列の式展開も利用すると、下記のコードになる (self省略)
  digest = send("#{attribute}_digest")
  return false if digest.nil?
  BCrypt::Password.new(digest).is_password?(token)
end
```
このままテストすると、`current_user`メソッドと`nil`ダイジェストのテストの両方で`authenticated?`が古いままになっており、引数も2つではなく1つのままのため  
これを解消するために、両者を更新して、新しい一般的なメソッドを使うようにする。

## 11.3.2 editメソッドアクションで有効化
`authenticated?`が完了。  
これでeditアクションを書く準備ができた。  
このアクションは`params`ハッシュで渡されたメールアドレスに対応するユーザーを認証する。
ユーザーが有効であることを確認する中核は、下記の部分。  
`if user && !user.activaed? && user.authenticated?(:activation, params[:id])`  
`user.activated?`に注目。  
このコードは、既に有効になっているユーザーを誤って再度有効化しないために必要。  
正当であろうとなかろうと、有効化が行われるとユーザーはログイン状態になる。  
もしこのコードがなければ、攻撃者がユーザーの有効化リンクを後から盗み出してクリックするだけで、本当のユーザーとしてログインできてしまう。  
そうした攻撃を防ぐためにこのコードは非常に重要。  
  上の論理値に基づいてユーザーを認証するには、ユーザーを認証してから`activated_at`タイムタンプを更新する必要がある
```
user.update_attribute(:activaed, true)
user.update_attribute(:activated_at, Time.zone.now)
```
上のコードを`edit`アクションで使う。  
下記のコードでは有効かトークンが向こうだった場合の処理も行われている点に注目。  
トークンが無効になるようなことは実際には滅多にないが、もしそうなった場合はルートURLにリダイレクトされる仕組み。  
`app/controllers/account_activations_controller.rb`  (アカウントを有効化する`edit`アクション)

```
class AccountActivationsController < ApplicationController

  def edit
    user = User.find_by(email: params[:email])
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.update_attribute(:activated,    true)
      user.update_attribute(:activated_at, Time.zone.now)
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
end
```
webページで新規登録して、サーバーのログのaタグのリンクを開くと、  
ユーザー認証が完了となる。  
  もちろん、この時点ではユーザーのログイン方法を変更していないので、ユーザーの有効化にはまの意味もない。  
ユーザーの有効化が役立つためには、ユーザーが有効である場合にのみログインできるようにログイン方法を変更する必要がある。  
これを行うためには、`user.activated?`がtrueの場合のみログインを許可して、そうでない場合はルートURLにリダイレクトして`warning`で警告する。  
`app/controllers/sessions_controller.rb/createアクション`(有効でないユーザーがログインすることのないようにする)  
これで、ユーザー有効か昨日の大まかな部分については実装できた。  
(有効化されていないユーザーが表示されないようにする必要もあり。)  
この時点では、テストはRED、なのでリファタリングを少々次で追加する

## 11.3.3 有効化のテストとリファタリング
ここでは、アカウント有効化の統合テストを追加する  
正しい情報でユーザー登録を行った場合のテスト(7.4.4)は既にあるので、  
追加する行数は多いが、基本的なことなので、復習も兼ねて。
`test/integration/users_signup_test.rb`(ユーザー登録のテストにアカウント有効化を追加する)  
重要なのは `assert_equal 1 ActionMailer::Base.deliveries.size`で  
上のコードは配信されたメッセージがきっかり1つであるかどうか確認するもの。  
配列`deliveries`は変数なので、setupメソッドでこれを初期化しておかないと、  
並列して行われる他のテストでメールが配信された時に、エラーが発生してしまう。  
`assigns`メソッドを使うと対応するアクション内のインスタンス変数にアクセスできるようになる。  
例えば、Userコントローラの`create`アクションでは`@user`というインスタンス変数が定義されているが、テストで`assigns(:user)`と書けば、インスタンス変数にアクセスできるようになる。  
.  
.  
テストができたので、ユーザー操作の一部をコントローラからモデルに移動するというささやかなリファタリングを行う準備ができた。  
ここでは、`activate`メソッドを作成してユーザーの有効化メールを更新し、  
`send_activation_email`メソッドを作成して有効化メールを送信する。
.  
.  
`app/models/user.rb` (Userモデルにユーザー有効化メソッドを追加する)  
|  
v  
`app/controllers/users_controller.rb` (ユーザーモデルオブジェクトからメールを送信する)  
`app/controllers/account_activations_controller.rb` (ユーザーモデルオブジェクト経由でアカウントを有効化する)  

Userモデルに追加したコードでは`user.`という記法を使っていない点に注目。  
Userモデルにはそのような変数はないので、`user.`があるとエラーになる。  
```
-user.update_attribute(:activated,    true)
-user.update_attribute(:activated_at, Time.zone.now)
+update_attribute(:activated,    true)
+update_attribute(:activated_at, Time.zone.now)
```  
(`user`を`self`に切替えるという手もあるが、`self`はモデル内では必須ではない)
Userメイラー内の呼び出しでは、`@user`が`self`に変更されている点にも注目。  

```
-UserMailer.account_activation(@user).deliver_now
+UserMailer.account_activation(self).deliver_now
```
.  
.  
どんな簡単なリファタリングであっても、この手の変更はつい忘れてしまうもの。  
テストをきちんと書くことで、この種の見落としを検証できるようにする。  

## 11.4 本番環境でのメール送信
ここまでの実装で、development環境に置けるアカウント有効化の流れは完成  
次は、サンプルアプリケーションの設定を変更して、  
production環境で実際にメールの送信できるようにしてみる。  
具体的には、まず無料のサービスを利用してメール送信の設定を行い、続いて  
アプリケーションの設定とデプロイを行う。  
.  
.  
本番環境からメール送信するために、「SendGrid」というHerokuアドオンを利用してアカウントを検証する。  
本チュートリアルでは「starter tier」というサービスを使う。  
これは1日400通までの制限で無料のもの。  
`$ heroku addons:create sendgrid:starter`

  herokuの処理が終わったら終了。  

# 12章 パスワードの再設定
11章でアカウントの有効化の実装が完了し、ユーザーのメールアドレスが本人のものである確信が得られるようになったので、これで ***パスワードの再設定*** に取り組めるようになった。  
本章では、アカウント有効化に似たようなもので、  
実際、幾つかの実装は11章での流れと同じだが、  
全てが同じとは言えない。  
例えば、アカウントの有効化の時と異なり、  
パスワードの再設定する場合はビューを1つに変更する必要があり、  
また、新しいフォームが新たに２つ(メールレイアウト用と新しいパスワードの痩身用)が必要になる  
.  
.   
コードを実際に書く前に、パスワード再設定の想定手順をモックアップで確かめる。  
まず、サンプルアプリケーションのログインフォームに「forget password」リンクを追加する。  
この「forget password」リンクをクリックするとフォームが表示され、そこにメールアドレスを入力してメールを送信すると、そのメールにパスワード再設定用のリンクが記載されています。  
この再設定用のリンクをクリックすると、ユーザーのパスワードを再設定して良いか確認を求めるフォームが表示される。  
.  
.  
11章で、パスワードの再設定用のメイラーが生成されているので、  
本章では、ここで生成したメイラーにリソースとデータモデルを追加して、  
パスワードの再設定の実現をしていく。  
.  
.  
アカウント有効化の際と似ていて、PasswordResetsリソースを作成して、  
再設定用のトークンとそれに対応するダイジェストを保存するのが目的。  
  *全体の流れ*
1. ユーザーがパスワードの再設定をリクエストすると、ユーザーが送信したメールアドレスをキーにしてデータベースからユーザーを見つける。
2. 街灯のメールアドレスがデータベースにある場合は、再設定用のトークンとそれに対応するリセットダイジェストを生成する。
3. 再設定用のダイジェストはデータベースに保存しておき、再設定用トークンはメールアドレスと一緒に、ユーザーに送信する有効化用メールのリンクに仕込んでおく。
4. ユーザーがメールのリンクをクリックしたら、メールアドレスをキーとしてユーザーを探し、データベース内に保存しておいた再設定用ダイジェストと比較する。（トークンを認証する）
5. 認証に成功したら、パスワード変更用のフォームをユーザーに表示する。  
.  
.  
## 12.1 PasswordResetsリソース
セッション(8章)やアカウント有効化(11章)の時と同様に、  
まずはPasswordResetsリソースのモデリングから始めていく。  
前章と同様に、今回も新たなモデルは作らずに、代わりに必要なデータ(再設定用のダイジェストなど)をUserモデルに追加していく形で進めていく。
.  
.  
PasswordResetsもリソースとして扱うので、  
ますは標準的なRESTfulなURLを用意する。  
有効化の時は`edit`アクションだけを取り扱いしたが、  
今回はパスワードを再設定するフォームが必要なので、  
ビューを描画するための`new`アクションと`edit`アクションが必要になる。  
また、それぞれのアクションに対応する作成用/更新用のアクションも最終的なRESTfulなルーティングには必要になる。
.  
.  
### 12.1.1 PasswordResetsコントローラ
準備が整ったところで、最初のステップでパスワード再設定用のコントローラを作る。
先ほど説明したように、今回はビューも扱うので、`new`アクションと`edit`アクションも一緒に生成している点に注意。  
```
$ rails g controller PasswordResets new edit --no-test-framework
```
上のコマンドでは、テストを生成しないオプションをつける。  
これはコントローラの単体テストをする代わりに、(11.3.3)から  
統合テストでカバーしてくため。  
.  
.  
また今回の実装では、新しいパスワードを再設定するためのフォームと、  
Userモデル内のパスワードを変更するためのフォームが必要になるので、  
`new`,`create`,`edit`,`update`のルーティングを用意しておく。  
この変更は、前回と同様にルーティングのファイルの`resources`行で行う。  
.  
`config/routes.rb`(パスワード再設定用リソースを追加する)  
.  
また、editとupdateの名前付きツートでは、＿pathではなく、＿urlを使う理由は、2つはメールのURLからアクセスするため。  
.  
.  
### 12.1.2 新しいパスワードの設定
パスワードの再設定のデータモデルも、アカウント有効化の場合と似ている。  
記憶トークン(9章)や有効かトークン(11章)での実装パターンに倣って、  
パスワードの再設定でも、トークン用の仮想的な属性とそれに対応するダイジェストを用意していく。  
もしトークンがハッシュ化せずに、データベースに保存してしまうと、  
攻撃者によってデータベース方トークンを読み出された時、セキュリティ上の問題がある。  
つまり、攻撃者がユーザーのメールアドレスにパスワード再設定のリクエストを送信し、  
このメールと盗んだトークンと組み合わせて攻撃者がパスワード再設定のリンクを開けば、  
アカウントを奪い取ることができてしまう。  
したがって、パスワードの再設定では必ず、ダイジェストを使うようにする。  
セキュリティ上の注意点はもう１つ。  
それは再設定用のリンクはなるべく短時間で ***期限切れ*** 似なるようにしなければならない。  
そのためには、再設定用のメールの送信時刻も記録する必要がある。  
以上の背景に基づいて、`reset_digest`属性と`reset_sent_at`属性をUserモデルに追加する。  

```
$ rails g migration add_reset_to_users reset_digest:string reset_sent_at:string

$ rails db:migrate
```
新しいパスワード再設定の画面を作成するために、前回紹介した手法を使う。  
新しいセッションを作成するためのログインフォームを使う。  
新しいパスワード再設定フォームは`app/views/sessions/new.html.erb`と似ているが、  
重要な違いとして、`form_for`で扱うリソースとURLが異なっている点と、パスワード属性が省略されている点があげられる。    
`app/views/password_resets/new.html.erb`を編集。    

### 12.1.3 createアクションでパスワード再設定
このフォームから送信を行った後、メールアドレスをキーとしてユーザーをデータベースから見つけ、パスワード再設定用トークンと送信時のタイムスタンプでデータベースの属性を更新する必要がある。  
それに続いてルートURLにリダイレクトし、フラッシュメッセージをユーザーに表示する。  
送信が向こうの場合は、ログインと同様に`new`ページを出力して`flash.now`メッセージを表示する。  
`app/controllers/password_resets_controller.rb` (パスワード再設定用の`create`アクションを編集)  
.  
.  
Userモデル内のコードは、`before_create`コールバック内で使われる`create_activation_digest`メソッドと似ている。  
`app/models/user.rb` (Userモデルにパスワード再設定用のメソッドを追加する)  
ここで示すように、この時点でのアプリケーションは、無効なメールアドレスを入力した場合に正常に動作する。  
正しいメールアドレスを送信した場合にもアプリケーションが正常に動作sるためには、パスワード再設定のメイラーメソッドを定義する必要がある。  
.  
.  
## 12.2 パスワード再設定のメール送信
