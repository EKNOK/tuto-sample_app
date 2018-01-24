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
また、新しいフォームが新たに２つ(メールレイアウト用と新しいパスワードの送信用)が必要になる  
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
それは再設定用のリンクはなるべく短時間で ***期限切れ*** になるようにしなければならない。  
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
正しいメールアドレスを送信した場合にもアプリケーションが正常に動作するためには、パスワード再設定のメイラーメソッドを定義する必要がある。  
.  
.  
## 12.2 パスワード再設定のメール送信

12.1のPasswordResetsコントローラで`create`アクションがほぼ動作するとことまで持ってきた。  
残すところは、パスワード再設定に関するメールを送信する部分。  
11.1をやっていれば、Userメイラー(`app/mailers/user_mailer.rb`)を作成した時に、デフォルトの`password_reset`メソッドもまとめて生成されているはずだが、必要であれば、生成する(`accouunt_activation`)に関するメソッド。  
.  
.  
### 12.2.1 パスワード再設定のメールとテンプレート
11.3.3ではUserメイラーにあるコードをUesrモデルに移すリファタリングを行った。  
同様のリファタリング作業をパスワード再設定に対しても行っていく。  
```
UserMailer.password_reset(self).deliver_now
```

上のコードの実装に必要なメソッドは、11.2で実装したアカウント有効化メイラーとほぼ一緒。  
最初に、Userメイラーに`password_reset`メソッドを生成して、続いて、テキストメールのテンプレートとHTMLメールのテンプレートをそれぞれ定義する。  
```
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
.
.
  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password reset"
  end
end
```
`app/views/user_mailer/password_reset.text.erb` (パスワード再設定用のテンプレート(テキスト))  
`app/views/user_mailer/password_reset.html.erb` (パスワード再設定用のテンプレート(HTML))  
アカウント有効化メールの場合（11.2）と同様、Railsのメールプレビュー機能でパスワード再設定のメールでプレビューする。そのためのコードはリスト11.18と同じ。  
HTMLとテキストメールをそれぞれプレビューできるようにする。  
そして、画面にて、正しいメールアドレスを送信した時には、flash[:success]のメッセージがルートURLで表示。  
このメールはサーバーログで確認すると、実際に送られたメールやURLが表示される。  
.  
.  
### 12.2.2 送信メールのテスト
アカウント有効化のテストと同様に、メイラーメソッドのテストを書いていく。  
`test/mailers/user_mailer_test.rb` (パスワード再設定用メイラーメソッドのテストを追加する)
これでテストはGREENになる。  

## 12.3 パスワードを設定する。
12.11で無事に送信メール素生成できたので、  
次は、PasswordResetsコントローラの`edit`アクションの実装を進めていく。  
また11.3.3と同様に統合テストを使ってうまく動作しているかのテストも行っていく。  
.  
.  
### 12.3.1 `edit`アクションで再設定
12.11で見せたパスワード再設定の送信メールには、次のようなリンクが含まれていた。  
`https://example.com/password_resets/3BdBrXeQZSWqFIDRN8cxHA/edit?email=fu%40bar.com`    
このリンクを機能させるためにはパスワード再設定フォームを表示するビューが必要。  
このビューは、ユーザーの編集フォームと似ているが、今回はパスワード入力フィールドと確認用フィールドだけで十分。  
.  
.  
ただし、今回の作業は少し面倒な部分がある。  
というのも、メールアドレスをキーとしてユーザーを検索するためには、  
`edit`アクションと`update`アクションの両方でメールアドレスが必要になるため。  
例のメールアドレス入りのリンクのおけげで、`edit`アクションでメールアドレスを取り出すことの問題はない。  
しかし、フォームを一度送信してしまうと、この情報は消えてしまう。  
この値はどこに保持しておくのは良いか。  
今回はこのメールアドレスを保持するため、 ***隠しフィールド*** としてページ内に保存する手法をとる。  これによって、他の情報と一緒にメールアドレスが送信されるようになる。  
フォームタグヘルパーを使っている点に注意する。  
`app/views/password_resets/edit.html.erb` (パスワード再設定のフォーム)  

```
hidden_field_tag :email, @user.email
```
これまでは次のようなコードを書いていたが、今回は違う。  

```
f.hidden_field_tag :email, @user.email
```
これは再設定用のリンクをクリックすると、  
前者(`hidden_field_tag`)では、メールアドレスが`params[:email]`に保存されるが、  
後者では、`params[:user][:email]`に保存されてしまう。  
.  
.  
今度は、このフォームを描画するためにPasswordResetsコントローラの`edit`アクション内で`@user`インスタンス変数を定義していく。  
アカウント有効化の場合と同様、`params[:email]`のメールアドレスに対応するユーザーをこの変数に保存する。  
続いて、`params[:id]`の再設定用のトークンと、11.26で抽象化した`authenticated?`メソッドを使い、このユーザーが正当なユーザーである(ユーザーが存在する、有効化されている、認証済みである)ことを確認する。
`edit`アクションと`update`アクションのどちらの場合も正当な`@user`が存在する必要があるので、　　
いくつかのbeforeフィルタを使って`@user`の検索とバリデーションを行う 　
`app/controllers/password_resets_controller.rb` (パスワード再設定の`edit`アクション)  
```
class PasswordResetsController < ApplicationController
  before_action :get_user,   only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  .
  .
  .
  def edit
  end

  private

    def get_user
      @user = User.find_by(email: params[:email])
    end

    # 正しいユーザーかどうか確認する
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end
end
```
上では次のコードを使っている。
```
authenticated?(:reset, params[:id])
```
これと下のコードを比較する。
```
authenticated?(:remember, cookies[:remember_token])
```
このコードは11.28で使われたコードで、、
```
authenticated?(:activation, params[:id])
```
これは11.31で使ったコード。  
以上にコードが認証メソッドである。  
また今回、追加したコードで全て実装が完了したことになる。
.  
.  
話を戻して、これでリンクを開いたときに、パスワード再設定のフォームが出力されるようになりました。  
### 12.3.2 パスワードを更新する。
AccountActivationsコントローラの`edit`アクションでは、ユーザーの有効化ステータスを`false`から`true`に変更したが、今回の場合はフォームから新しいパスワードを送信するようになっている。  
したがって、フォームから送信に対応する`update`アクションは必要になる。  
この`update`アクションでは、次の4つのケースを考慮する必要がある。  
1. パスワード再設定の有効期限が切れていないか。
2. 無効なパスワードであれば、失敗させる。(理由も表示)
3. 新しいパスワードがから文字列になっていないか(ユーザー編集ではOK)
4. 新しいパスワードが正しければ、更新する。  
(1), (2), (4)はこれまでの知識で対応できそうだが、  
(3)はどのように対応すれば良いか、あまり明確ではない。  
とりあえず、上のケースを１つずつ対応していくことにする。  
.  
.  
(1)については、`edit`と`update`アクションに次のようなメソッドとbeforeフィルターを用意することで対応できる。  
```
# (1)の対応案
bedore_action :check_expiration, only: [:edit, :update]

```
この`check_expiration`メソッドは、有効期限をチェックするPrivateメソッドとして定義する。  
```
# 期限切れかどうかを確認する
def check_expiration
  if @user_password_reset_expired?
    flash[:danger] = "Password reset has expired. "
    redirect_to new_password_reset_url
  end
end
```
上の`check_expiration`メソッドでは、期限切れかどうかを確認するインスタンスメソッド「`password_reset_expired?`」を使っている。  
この新しいメソッドについては、後ほど説明するとこにする。  
今は、上記の４つのケース二ついて考える。  
.  
.  
まず、上のbeforeフィルターで保護した`update`アクションを使うことで、(2),(4)のケースに対応することができる。
例えば、(2)については、更新が失敗したときに`edit`のビューが再描画され、12.14のパーシャルにエラーメッセージ表示されるようにすれば、解決できる。  
(4)については、更新が成功したときにパスワードを再設定し、あとは、ログインに成功したときと同様に処理を進めていけば問題なさそう。
.  
.  
今回の小難しい問題点は、パスワードが空文字だった場合の処理で、  
というもの、以前Userモデルを作っていたときに、パスワードがからでも良い(10.13の`allow_nil`)という実装をしたからである。  
したがって、このケースについては明示的に、キャッチするコードを追加する必要がある。  
これが、先ほど、示した考慮すべき点の(3)にあたる。  
これを解決する方法として、今回は`@user`オブジェクトにエラーメッセージを追加する方法をとってみる。  
具体的には、次のように、`errors_add`を使ってエラーメッセージを追加する。  
```
@user.errors.add(:password, :blank)
```
このように書くと、パスワードが空だったときに空の文字列に対するデフォルトのメッセージを表示してくれるようになる。  
.  
.  
以上の結果をまとめるを、(1)の`password_reset_expired?`の実装を除き、全てのケースに対応した`update`アクションが完成する。
`app/controllers/password_resets_controller.rb` (パスワード再設定の`update`アクション)  
上で編集したコードでは、7.3.2で実装したときと同様に、`user_params`メソッドを使って`password`と`password_confirmation`属性を精査している点に注意。  
あとは、残しておいた12.16の実装だけ。  
今回は先回りして、始めたUserモデルに移譲する前提で、次のコードを書いていた。  
```
@user.password_reset_expired?
```
上のコードを動作させるために、`password_reset_expired?`メソッドをUserモデルで定義していく。12.2.1を参考に、このメソッドでは、パスワード再設定の期限を設定して、2時間以上パスワードが再設定されなかった場合は、期限切れとする処理を行う。  
これをRubyで表すと、次のようになる。  
```
reset_sent_at < 2.hour.ago
```
上の`<`記号を「〜より少ない」と読んでしまうと、「パスワード再設定メール送信時から経過した時間が、2時間より少ない場合」となってしまい、困惑してしまうので注意。  
ここで行っている処理は、「少ない」ではなく、「早い」と捉えると理解しやすい。  
つまり、`<`記号を「〜より早い時刻」を読む。  
こうすると、「パスワード再設定メールの送信時刻が、現在時刻より2時間以上前の場合」となり、***期待通り*** の条件となる。  
したがって、この条件が満たされるかどうか確認する。  
`password_reset_expired?`メソッドは、12.17のようになる。  
`app/models/user.rb` (Userモデルにパスワード再設定用メソッドを追加する)  
```
# パスワード再設定の期限が切れている場合はtrueを返す
def password_reset_expired?
  reset_sent_at < 2.hours.ago
end
```
上尾のコードを使うと、`update`アクションが動作するようになる。  
送信が無効だった場合と有効だった場合の画面をそれぞれ表示できる。  

### 12.3.3 パスワードの再設定をテストする。
この項では、12.16の2つ(また3つ目は演習)の分岐、つまり痩身に成功した場合と失敗した場合の統合テストを作成する。  
まずはパスワード再設定のテストファイルを生成する。  
`test/integration/password_resets_test.rb`  
パスワード再設定をテストする手順は、アカウント有効化のテストと多くの共通点があるが、  
テストの冒頭部分には次のような違いがある。  
最初に「forgot password」フォームを表示して無効なメールアドレスを送信する。  
後者では、パスワード再設定トークンが作成され、再設定用メールが送信される。  
続いて、メールのリンクを開いて、無効な情報を送信し、  
次にそのリンクから有効な情報を送信して、  
それぞれが期待通りに動作することを確認する。  
*このテストはコードリーディングのよい練習台なるのでみっちりお読みください..*  
.  
`test/integration/password_resets_test.rb` (パスワード再設定の統合テスト)  
```
require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # メールアドレスが無効
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # メールアドレスが有効
    post password_resets_path,
         params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # パスワード再設定フォームのテスト
    user = assigns(:user)
    # メールアドレスが無効
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # 無効なユーザー
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # メールアドレスが有効で、トークンが無効
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # メールアドレスもトークンも有効
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # 無効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "barquux" } }
    assert_select 'div#error_explanation'
    # パスワードが空
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "",
                            password_confirmation: "" } }
    assert_select 'div#error_explanation'
    # 有効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "foobaz" } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
```

上のコードの大半は本チュートリアルで概出。
今回新しいのは`input`タグ。

`assert_select "input[name=email][type=hidden][value=?]", user.email`

上のコードは、`input`タグに正しい名前、type="hidden"、メールアドレスがあるかどうか、確認する。

`<input id="email" name="email" type="hidden" value="michael@example.com">`

以上でテストは GREEN になる。  
**演習**
## 12.4 本番環境でのメール送信(再掲)
これでパスワード再設定の実装も終わり。  
あとは、全勝と同様に、development環境だけでなく、  
production環境でも動くようにするだけ。  
セットアップの手順はアカウント有効化と全く同じ。  
.  
.  
本番環境からメール送信するために、「SendGrid」というHerokuアドオンを利用してアカウントを検証する。  
本チュートリアルでは、「starter tier」というサービスを使うことでi日400通まで無料で使うことができる。  

# 13章 ユーザーのマイクロポスト
サンプルアプリケーションのコアな部分を開発するために、  
これまでにユーザー、セッション、アカウント有効化、パスワードリセットという４つのリソースについて見てきた。  
そして、これらのうち「ユーザー」というリソースだけが、ActiveRecordによってデータベース上のテーブルと紐付いている。  
全ての準備が整った今、ユーザーが短いメッセージを投稿できるようにするためのリソース「***マイクロポスト***」を追加していきます。  
この章では、Micropostデータモデルを作成し、Userモデルと`has_many`及び`belong_to`メソッドを使って関連付けを行う。  
さらに結果を処理し表示するために必要なフォームとその部品を作成する。  
14章では、マイクロポストのフィードを受け入れるために、ユーザーをフォローするという概念を導入し、Twitterのようなアプリケーションを作る。  

## 13.1 基本的なモデル
Micropostモデルは、マイクロポストの内容を保存する`content`属性と、特定のユーザーとマイクロポストを関連付ける`user_id`属性の2つの属性だけを持つ。  
実行した結果のMicropostモデルの構造は以下..  

| Microposts                 | |
|:-------------|:--------------|
| id           | integer       |
| content      | text          |
| user_id      | integer       |
| created_at   | datetime      |
| updated_at   | datetime      |

.  
.  
このモデルでは、マイクロポストの投稿に`String`型ではなく、  
`Text`型を使っている点に注目。  
これは、ある程度の量のテキストを格納できる時に使われる型。  
`String`型でも255文字まで格納できるため、この後やるこの型でも140文字制限を満たせるが、  
`Text`型の方が表現豊かなマイクロポストを実現できる。  
例えば、投稿フォームにStringようのテキストフィールドでは、なくてText用ののテキストエリアを実現できる。  
また、`Text`型の方が将来に置ける柔軟性に飛んでいて、  
例えば国際化するとき、言語に応じて投稿の長さを調節することができる..  
さらに、`Text`型を使っていても本番環境で、パフォーマンスの差はでない  
これらの理由から、デメリットよりもメリットの方が多い。  
.  
.  
6.1でUserモデルを生成したとき同様に、Railsの`g model`コマンドを使いMicropostモデルを生成していく。  
`rails g model Micropost content:text user:reference`
これで、Micropostモデルが生成される。  
つまり、`ApplicationRecord`を継承したモデルが作られる。  
ただし、今回は生せされたモデルの中に、ユーザーと１対１の関係であることを表す`belongs_to`のコードも追加される。  
これは先ほどのコマンドで`user:references`の引数も含めていたから。  
.  
.  
データベースに`users`テーブルを作るマイグレーションを生成したときと同様に、この`generate`コマンドは`microposts`テーブルを生成するためのマイグレーションを生成します。  
.  
.  
Userモデルとの最大の違いは`references`型を利用している点。  
これを利用すると、自動的にインデックスと外部キー参照付きの`user_id`カラムが追加され、UserとMicropostを関連付ける下準備をしてくれる。  
Userモデルのときと同じで、Micropostモデルのマイグレーションファイルでも`t.timestamps`という行(マジックカラム)が自動的に生成される。  
これにより、`created_at`と`updated_at`というカラムが追加される。  
なお、`created_at`カラムはマイクロポストを改良していく点について、必要なカラムになる。

```
class CreateMicroposts < ActiveRecord::Migration[5.0]
  def change
    create_table :microposts do |t|
      t.text :content
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_index :microposts, [:user_id, :created_at]
  end
end
```

ここで、`user_id`と`created_at`カラムにインデックスが付与されている点に注目。  
こうすることで、`user_id`に関連付けた全てのマイクロポストを作成時刻の逆順で取り出しやすくなる。  
また、`user_id`と`created_at`の両方を1つの配列に含まれている点にも注目。  
こうすることでActive Recordは ***両方のキー*** を同時に扱う ***複合機ーインデックス*** を作成する。  
ここで、マイグレーションを使い、データベースを更新する。  

### 13.1.2 Micropostのバリデーション
基本的なモデルはできたので、次にバリデーションを追加する。  
Micropostモデルを作成したときに、`user_id`をもたせるようにしたので、これを使って慣習的にただしくActive Recordの関連付けを実装していく。  
まずは`Micropost`モデル単体を動くようにしてみる。  
.  
.  
Micropostの初期テストはUserモデルの初期テストと似ている。  
まずは`setup`でfixtureのサンプルユーザーと紐付けた新しいマイクロポストを作成していく。  
次に、再生したマイクロポストが有効かどうかをチェックしていく。  
最後に、あらゆるマイクロポストはユーザーのidを持っているべきなので、`user_id`の存在性のバリデーションに対するテストを追加していく。
`validates :user_id, presence: true`
.  
.  
ちなみにRails5では、バリデーションを追加しなくてもテストが成功する。  
しかし、ハイライトした「慣習的な意味でただしくない」というコードを書いた場合でのみ発生する。  
この部分を「慣習的に正しい」コードで実装すると、`user_id`に対する存在性のバリデーションが期待通りに動く。  
これで、テストがGREENになる。  
.  
.  
次にマイクロポストの`content`属性に対するバリデーションを追加する。  
`user_id`属性と同様に、`content`属性も存在する必要があり、さらにマイクロポストが140(micro)文字以内の制限を加える。  
.  
.  
Userモデルにバリデーションを追加したときと同様に、テスト駆動開発でMicropostモデルのバリデーションを追加していく。  
基本的には、Userモデルの時と同じようなバリデーションを追加していく。  
`test/models/micropost_test.rb` (Micropostモデルのバリデーションに対するテスト)  
`app/models/micropost.rb` (Micropostモデルのバリデーション)  
これで、全てのテストがGREENになる。  

### 13.1.3 User/Micropostの関連付け
Webアプリケーション用のデータモデルを構築するにあたって、個々のモデル間での ***関連付け*** を十分に考えておくことが重要。  
今回の場合は、それぞれのマイクロポストは1人のユーザーと関連付けられ、それぞれのユーザーは（潜在的に）複数のマイクロポストと関連付けられる。  
これらの関連付けを実装するための一環として、Micropostモデルに対するテストを作成し、さらにUserモデルにいくつかテストを追加する。  
この節で定義する`belongs_to/has_many`関連付けを使うことで、下のメソッドをRailsで使えるようになる。  

| メソッド                       | 用途                         |
|:------------------------------|:----------------------------|
| `micropost.user`              | Micropostに紐付いたUserオブジェクトを返す  |
| `user.microposts`             | Userのマイクロポストの集合を返す           |
| `user.microposts.create(arg)` | `user`に紐付いたマイクロポストを作成する    |
| `user.microposts.create!(arg)` | `user`に紐付いたマイクロポストを作成する(失敗時に例外を発生) |
| `user.microposts.build(arg)`   | `user`に紐付いた新しいMicropostオブジェクトを返す |
| `user.microposts.find_by(id: 1)` | `user`に紐付いていて、`id`が`1`であるマイクロポストを検索する |

これらのメソッドは使うと、紐付いているユーザーを ***通して*** マイクロポストを作成することができる。(慣習的に正しい方法)  
新規のマイクロポストがこの方法で作成される場合、`user_id`は自動的に正しい値に設定される。  

```
@user = users(:michael)  
# 下のコードは慣習的に正しくない
# @micropost = Micropost.new(content: "Lorem ipsum", user_id: @user.id)
@micropost = @user.microposts.bulid(content: "hello")
```

(`new`メソッド同様に`bulid`はオブジェクトを返すが、データベースには反映されない)  
一度正しい関連付けを定義してしまえば、`@micropost`変数の`user_id`には、関連するユーザーのidが自動的に設定される。
.  
.  
`@user.microposts.build`のようなコードを使うためには、UserモデルとMicropostモデルをそれぞれ更新して、関連づける必要がある。  
Micropostモデルの方では、`belongs_to :user`というコードが必要になるが、これはマイグレーションによって自動的に生成されているはず。  
一方で、Userモデルの方では、`has_many :microposts`と追加する必要がある。  
ここは自動的に生成されなので手動で入力。  

### 13.1.4 マイクロポストを改良する
この項では、UserとMicropostの関連づけを改良していく。  
具体的には、ユーザーのマイクロポストを特定ん順序で取得できるようにしたり、マイクロポストをユーザーに依存させて、ユーザーが削除されたら、マイクロポストも自動的に削除されるようにしていく。  
.  
.  
`user.microposts`メソッドはデフォルトでは、読み出しの順序に対して何も保証しないが、ブログや、Twitterの習慣にしたがって、作成時間の逆順、つまり最も新しいマイクロポストをさいそに表示するようにしてみる。
これを実装するためには、**default scope** というテクニックを使う。  
.  
.  
この機能のテストは、見せかけの成功に陥りやすい部分で「アプリケーション側の実装が本当は間違っているのにテストが成功してしまう。」ことがある。  
正しいテストを書くために、ここでは、テスト駆動開発で進めていく。
具体的には、まずデータベース上の最初のマイクロポストが、fixture内のマイクロポスト(`most_recent`)と同じであるか検証するテストを書いていく。  
`test/models/micropost_test.rb` （マイクロポストの順序づけをテストする）  
マイクとポスト用のfixtureファイルからサンプルデータを読み出しているので、次のfixtureファイルも必要になる。  
`test/fixtures/microposts.yml` (マイクロポスト用のfixture)  
ここでは、埋め込みRubyを使って`created_at`カラムに明示的に値をセットしている点について注目する。  
このマジックカラムはRailsによって自動的に更新されるため、基本的には手動で更新することは、できないがfixtureファイルの中でそれが可能になっている。  
また、原理的には必要ないかもしれないが、ほとんどのシステムでは上から順に作成されるので、fixtureファイルでも意図的に順序をいじっている。  
この時点でtestはREDになる。  
.  
.  
次に,
Railsの`default_scope`メソッドを使ってこのテストを成功させる。  
このメソッドは、データベースから要素を取得した時のデフォルト順を指定するメソッド。  
特定の順序にしたい場合は、`default_scope`の引数に`order`を与える。  
例えば、`created_at`カラムの順にしたい場合は、  
`order(:created_at)`にする。  
ただし、デフォルトの順序が昇順(ascending)となっているので、このままでは、数の小さい値から大きい値にソートされてしまう。  
逆にしたい場合は、次のように生のSQLを与える必要がある。  
`order('created_at DESC')`  
ここで使った`DESC`とは、SQLの降順（descending）を示す。  
したがって、これで新しい順になる。  
また、Rails4.0から`order(created_at: :desc)`でもかけるようになった。  
`app/models/micropost.rb` (`default_scope`)でマイクロポストを順序付ける。  
.  
`default_scope{ order(created_at: :desc) }`  
.  
これは、ラムだ式(Stabby lambda)という文法で、procやlambda(もしくは無名関数)と呼ばれるオブジェクトを作成する文法。  
`->`のラムダ式は、ブロックを引数に取り、Procオブジェクトを返す。  
このオブジェクトは、`call`メソッドが呼ばれた時、ブロック内の処理を評価する。  
これをコンソールで確認すると..  

```
>> -> { puts "foo" }
=> #<Proc:0x007fab938d0108@(irb):1 (lambda)>
>> -> { puts "foo" }.call
foo
=> nil
```

これでテストはGREENになる。  
.  
.  
*Dependent: destroy*  
今度はマイクロポストに第二の要素を追加してみる。  
サイト管理者は、ユーザーを破棄する権限を持つ。  
ユーザーが破棄された場合、ユーザーのマイクロポストも同様に破棄されるべき。  
.  
これは`has_many`メソッドにオプションを渡してあげることで実装できる。  
`app/models/user.rb` (マイクロポストは、そのユーザーと一緒に破棄されることを保証する。)  
`dependent: :destroy`というオプションを使うと、ユーザーが削除された時に、そのユーザーに紐付いたマイクロポストも一緒に削除される。  
.  
.  
次に、テストを使ってUserモデルを検証してみる。  
このテストでは、 (idを紐づけるための) ユーザーを作成することと、そのユーザーに紐付いたマイクロポストを作成する必要がある。その後、ユーザーを削除してみて、マイクロポストの数が1つ減っているかどうかを確認する。  
これでテストがGREENになる。  
## 13.2 マイクロポストを表示する。
Web経由でマイクロポストを作成する方法は現時点では穴井が、マイクロポストを表示することと、テストすることは可能になった。  
ここでは、Twitterのような独立したマイクロポストの`index`ページは作らずに、ユーザーの`show`ページで直接マイクロポストを表示させることにする。  
ユーザープロフィールにマイクロポストを表示させるため、最初に極めてシンプルなERbテンプレートを作成する。次に、10.3.2でのサンプルデータ生成タスクにマイクロポストのサンプルを追加して、画面にサンプルデータが表示されるようにしてみる。  
### 13.2.1 マイクロポストの描画
本項では、ユーザーのプロフィール画面 (`show.html.erb`) でそのユーザーのマイクロポストを表示させたり、これまでに投稿した総数も表示させたりしていく。  
とはいえ、今回必要となるアイデアのほとんどは、10.3で実装したユーザーを表示する部分と似ている。  
.  
.  
まずは、Micropostのコントローラとビューを作成するために、コントローラを生成する。なお、今回使うのはビューだけで、Micropostsコントローラは 13.3から使っていく。  
`rails g controller Microposts`  
まずは、パーシャルで、順序なしリストの`ul`タグでなく順序付きリスト`ol`タグを使っている点に注目  
これはマイクロポストが特定の順序(新しい→古い)に依存しているため。  
次に対応するパーシャルを書く。  
`app/views/microposts/_micropost.html.erb` (1つのマイクロポストを表示するパーシャル)  
ここでは`time_ago_in_words`というヘルパーメゾッドを使う。  
これは、「3分前に投稿」といった文字列を出力。また`paginate`メソッドを使う。  

実は、`<%= will_paginate %>`は引数なしで動いていた。  
これは、`will_paginate`がUserコントローラのコンテキストにおいて。`@user`インスタンス変数は、`ActiveRecord::Relation`クラスのインスタンス。今回の場合はUsersコントローラのコンテキストからマイクロポストをページネーションしたいため、明示的に`@microposts`変数を`will_paginate`二渡す必要がある。  
したがって、そのようなインスタンス変数をUserコントローラの`show`アクションで定義しなければならない。  
`app/controllers/user_controller.rb` (`@microposts`インスタンス変数を`show`アクションに追加する)  

```
def show
  @user = User.find(params[:id])
  @microposts = @user.microposts.paginate(page: params[:page])
end
```

`paginate`メソッドのすばらしさ(笑)に注目。マイクロポストの関連づけを経由してmicropostテーブルに到達し、必要なマイクロポストのページを引き出してくれる。  
最後の課題はマイクロポストの投稿数を表示することだが、これは`count`メソッドを使うことで解決できる。  
.  
.  
`paginate`と同様に、関連づけを通して`count`メソッドを呼び出すことができる。大事なことは、`count`メソッドでは、データベース上のマイクロポストを全部読み出してから結果に対して`length`を呼ぶ、といった無駄な処理はしていけないという点。そんなことをしたら、マイクロポストの数が増加するにつれて効率が低下してしまう。そうではなく、データベースに変わりに計算してもらい、特定の`user_id`に紐付いたマイクロポストの数をデータベースに問い合わせている。  
.  
.  
これで全ての要素が揃ったので、プロフィール画面にマイクロポストを表示させてみる。  
`app/views/users/show.html.erb` (マイクロポストをユーザーのshowページに追加する)  

### 13.2.2 マイクロポストのサンプル
サンプルデータを生成タスクにマイクロポストも追加する。  
すべてのユーザーにマイクロポストを追加しようとすると時間が掛かり過ぎるので、takeメソッドを使って最初の6人だけに追加します。  
(このとき、orderメソッドを経由することで、明示的に最初の (IDが小さい順に) 6人を呼び出すようにしています。)  
`User.order(:created_at).take(6)`  
`db/seeds.rb`　（サンプルデータにマイクロポスト）を追加する。  
`app/assets/stylesheets/custom.scss` (マイクロポスト用のCSS)  
各マイクロポストの表示には、3つのどの場合にも、それが作成されてからの時間 ("1分前に投稿" など) が表示されていることに注目。これは13.22のtime_ago_in_wordsメソッドによるもの。数分待ってからページを再度読み込むと、このテキストは自動的に新しい時間に基づいて更新される。  

# 13.2.3　プロフィール画面のマイクロポストをテストする。  
この項では、プロフィール画面で表示されるマイクロポストに対して、統合テストを書いていく。まずは、プロフィール画面用の統合テストを生成してみる。  
`rails g integration_test users_profile`  
プロフィール画面におけるマイクロポストをテストするためには、ユーザーに紐付いたマイクロポストのテスト用データが必要になる。Railsの慣習に従って、関連付けされたテストデータをfixtureファイルに追加すると、次のようになる。  
`test/fixtures/microposts.yml` (ユーザーと関連付けたマイクロポストのfixture）  
`user`に`michael`という値を渡すと、Railsはfixtureファイル内の対応するユーザーを探し出して、(もし見つかれば) マイクロポストに関連付けてくれる。  
.  
.  
テストデータの準備は完了したので、これからテストを書いていくが、今回のテストはやや単純。今回のテストでは、プロフィール画面にアクセスした後に、ページタイトルとユーザー名、Gravatar、マイクロポストの投稿数、そしてページ分割されたマイクロポスト、といった順でテストしていきます。作成したコードをリスト 13.28に示す。(Applicationヘルパーを読み込んだことでリスト 4.2のfull_titleヘルパーが利用できている点に注目してください。)  
`test/integration/users_profile_test.rb` (Userプロフィール画面に対するテスト)  
マイクロポストの投稿数をチェックするために、第12章の演習 (12.3.3.1) で紹介したresponse.bodyを使っています。名前を見ると誤解されがちだが、response.bodyにはそのページの完全なHTMLが含まれています (HTMLのbodyタグだけではありません)。したがって、そのページのどこかしらにマイクロポストの投稿数が存在するのであれば、次のように探し出してマッチできるはず。  
`assert_match @user.microposts.count.to_s, response.body`  
これは`assert_select`よりもずっと抽象的なメソッドで、特に`assert_select`では、HTMLではどのHTMLタグを探すのか伝える必要があるが、`assert_match`メソッドでは、その必要がない点が違う。  
また、`assert_select 'h1>img.gravatar'`  
このように書くことで、`h1`タグの内側にある、`gravatar`クラス付きの`img`タグがあるかどうかチェックできる。  
これでテストはGREENになる。  

## 13.3 マイクロポストを操作する。  
データのモデリングとマイクロポスト表示のテンプレートの両方が完成したので、次はWeb経由でそれらを作成するためのインターフェイスに取り掛かるに取り掛かる。  
この節では、 ***ステータスフィード*** の初めをやる。  
最後にユーザーがマイクロポストをWeb経由で破棄できるようにする。  
.  
.  
従来のRails開発の習慣と異なる点が１つ。  
Micropostsリソースへのインターフェイスは、主にぷrフィールページとHomeページのコントローラを経由して実行されるので、、Micropostsコントローラには`new`や`edit`のようなアクションは不要ということになる。  
つまり、`create`と`destroy`があれば十分。
`config/routes.rb` (マイクロポストリソースのルーティング)  

### 13.3.1 マイクロポストのアクセス制御
Micropostsリソースの開発では、Micropostsコントローラないのアクセス制御から始める。  
関連付けられたユーザーを通してマイクロポストにアクセスするので、`create`アクションや、`destroy`アクションを利用するユーザーは、ログイン済みでなければならない。  
.  
.  
ログイン済みかどうか確かめるテストでは、Userコントローラ用のテストがそのまま役に立つ。  
つまり、正しいリクエストを書くアクションに向けて発行し、マイクロポストの数が変化していないかどうか、また、リダイレクトされるかどうかを確かめれば良い。  
`test/controllers/microposts_controller_test.rb` (Micropostsコントローラの認可テスト)  
このテストにパスするコードを書くためには、少しアプリケーション側のコードをリファタリングしておく必要がある。というのも１０章では、beforeフィルターの`logged_in_user`メソッドを使って、ログイン要求したことについて思い出すと、あの時はUsersコントローラ内にこのメソッドがあったので、beforeフィルターでしてしたが、このメソッドはMicropostsコントローラでも必要。そこで、各コントローラーが継承するApplicationコントローラにこのメソッドを移す。  
`app/controllers/application_controller.rb` (`logged_in_user`メソッドをApplicationコントローラに移す)  
`app/controllers/users_controller.rb` (Usersコントローラ内の`logged_in_user`フィルターを削除する)  
Micropostsコントローラからも`logged_in_user`メソッドを呼び出せるようになったので、これによって、`create`アクションや、`destroy`アクションに対するアクセス制限が、beforeフィルターで簡単に実装できるようになった。  

### 13.3.2 マイクロポストを作成する
第7章では、HTTP POSTリクエストをUsersコントローラの`create`アクションに発行するHTMLフォームを作成することで、ユーザーのサインアップを実装した。マイクロポスト作成の実装もこれと似ています。主な違いは、別の micropost/new ページを使う代わりに、ホーム画面 (つまりルートパス) にフォームを置くという点。  
.  
.  
最後にホーム画面を実装したときは、[Sign up now!] ボタンが中央にあった。マイクロポスト作成フォームは、ログインしている特定のユーザーのコンテキストでのみ機能するので、この節の一つの目標は、ユーザーのログイン状態に応じて、ホーム画面の表示を変更すること。
.  
.  
次に、マイクロポストのcreateアクションを作り始める。このアクションも、ユーザー用アクションと似ている。違いは、新しいマイクロポストをbuildするためにUser/Micropost関連付けを使っている点。micropost_paramsでStrong Parametersを使っていることにより、マイクロポストのcontent属性だけがWeb経由で変更可能になっている点に注目。
`app/controllers/microposts_controller.rb` (Misropostsコントローラの`create`アクション)  
`app/views/static_pages/home.html.erb` (Homeページ (/) にマイクロポストの投稿フォームを追加する)   
`app/views/shared/_user_info.html.erb`  (サイドバーで表示するユーザー情報のパーシャル)  
`app/views/shared/_micropost_form.html.erb` ( マイクロポスト投稿フォームのパーシャル)  
プロフィールサイドバー13章.24のときと同様、のユーザー情報にも、そのユーザーが投稿したマイクロポストの総数が表示されていることに注目。ただし少し表示に違いがある。  
プロフィールサイドバーでは、 “Microposts” をラベルとし、「Microposts (1)」と表示することは問題ない。しかし、今回のように “1 microposts” と表示してしまうと英語の文法上誤りになってしまいます。そこで、7.3.3で紹介した`pluralize`メソッドを使って “1 micropost” や “2 microposts” と表示するように調整していく。  
.  
.  
次はマイクロポスト作成フォームを定義する。  
`app/views/shared/_micropost_form.html.erb` (マイクロポスト投稿フォームのパーシャル)  
`app/controllers/static_pages_controller.rb` (`home`アクションにマイクロポストのインスタンス変数を追加する
)
