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
```
store_location, redirect_back_or
```　

メソッドを使い作る
なお、これらのメソッドはSessionsヘルパーで定義する。
(app/helpers/sessions_helper.rb)

リスト10.31~~~
