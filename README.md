# Inv1_cognito

# 実現したいこと

- Cognito をローカルで再現し、Next から認証をする
  - 認証をしたことを確認するために Next 側でログイン画面を設置
  - ログインすると見れるダッシュボードを用意したい

# やらないといけないこと

- [x] Cognito のコンテナを用意
- [x] Cognito(AWS 環境)を操作する踏み台コンテナを用意
  - [ ] Next のコンテナからでもいいかも？
- [ ] 認証できるかを試す
- [ ] Next でログイン画面を用意
- [ ] Next で認証画面を用意

# 使い方やコマンド

### 踏み台コンテナ経由で AWS コマンドの流し込み

```
dcr -e BOOT_FILE_NAME=XXXXXXX bastion
```

XXXXXX に該当するコマンドが打てるようになった

```
-e TTY=true
```

オプションでこいつをつけるとそのままコンテナを残せる

### AWS の設定について

docker を落とすと永続化されないので落ちてしまう。
もし永続化させたい場合は boot.sh の中で最初に叩かせるといいと思う

# 実装

### Cognito のコンテナを用意

https://ma-vericks.com/blog/build-cognito-in-docker/

この記事丸パクリでコンテナを作成

### 踏み台コンテナを用意

AWS CLI が叩けるコンテナを用意したかったので公式からパクる

https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-docker.html

### 立ち上げ

moto server 側は立ち上がったが、aws cli の方がエラー吐いて死んだ

```sh
dcr bastion aws --version
```

これもだめ
設定ファイルを追加してみて下記を実行

```sh
dcr bastion --version
```

これでとりあえず叩けた

何が良かったのかわからないのでとりあえず設定ファイルの追加をはずしてみる

設定ファイルはなくても動いた

aws を頭につけてたのが悪かったみたい

### sh ファイルで実行できるようにしてみる

長いコマンドを打つときに docker-comopose run で実行するの嫌やから sh を書いてそれに実行させたい

普通に dcr の引数にして sh を作って叩いたら落ちた

記事に書いてあるとおり下記を dockerfile に書いたらうまく呼び出せた

```
entrypoint: sh -c "chmod +x /bastion/bash/sample.sh && /bastion/bash/sample.sh && tail -f /dev/null"
```

よくわからんからおさらいもかねて記載

この`entrypoint`の設定は、Docker コンテナが起動したときに実行されるコマンドを指定しています。具体的には以下のような意味があります：

- `sh -c "..."`：シェルを起動し、ダブルクォーテーション内のコマンドを実行します。
- `chmod +x /bastion/bash/sample.sh`：`/bastion/bash/sample.sh`というスクリプトに実行権限を付与します。これにより、このスクリプトを実行可能な状態にします。
- `/bastion/bash/sample.sh`：上記で実行権限を付与したスクリプトを実行します。
- `&&`：左側のコマンドが成功した場合（終了ステータスが 0 の場合）に、右側のコマンドを実行します。これにより、複数のコマンドを一連の処理として順番に実行することができます。
- `tail -f /dev/null`：何もしないでコンテナを起動し続けます。`tail -f /dev/null`は、新たな出力があるまで`/dev/null`を読み続けるコマンドですが、`/dev/null`には新たな出力がないため、結果として何もせずに待機し続けることになります。

最後の`tail -f /dev/null`がよかったんやなぁ
`tty:true`でもいいんかなと思ったけど何があかんのやろ

`tail -f /dev/null`を取ったら実行後ちゃんと落ちてくれたからこっちを採用

### ユーザプールの作成

```sh
  aws cognito-idp create-user-pool \
    --pool-name MyUserPool \
    --alias-attributes "email" \
    --username-attributes "email" \
    --query UserPool.Id \
    --output text \
    --endpoint-url ${ENDPOINT_URL} \
    --schema \
        Name=email,Required=true


You must specify a region. You can also configure your region by running "aws configure".
```

aws の設置値を戻す

```sh
Invalid endpoint: http://aws_local:4000
```

怒られたのでドキュメントを確認

```
  mock-aws-local:
    image: motoserver/moto:latest
    container_name: "mock-aws-local"
    environment:
      MOTO_PORT: 4000
    ports:
      - "4000:4000"
    networks:
      - external
      - default
```

networks に知らないのがついてる

見よう見まねて追加

無駄やったけどコンテナ名を「-」にしたらいけた

## 認証をコマンドで試してみる

試すコマンド一覧

#### ユーザプールの作成

```sh
aws cognito-idp create-user-pool
```

名前通りユーザをプールする場所を作成する
`--schema`を設定することでテーブル的に利用できそうな雰囲気がある

オプションでできること

- パスワードのバリデーション
  - 長さ
  - 大文字小文字
  - 数字
  - 記号
- 削除保護？的なやつ
- Lambda の連携設定
- email と電話番号の検証
- ユーザ ID をどれにするか指定
- SMS かメールでのか検証連絡
- MFA 対応
- パスワード忘れた時の対応

#### アプリクライアントの作成

```sh
aws cognito-idp create-user-pool-client
```

アプリがアクセスするエンドポイントを作成する

オプションでできること

- 認証の追加
- トークンごとの時間制限
- 認証方法についてフロー設定

#### 管理者ユーザーの作成

```sh
aws cognito-idp admin-create-user
```

これは admin がユーザを登録する機能と考えていい
クライアント経由でアカウントを登録するからと認識した

オプションでできること

- 追加情報の付与(ユーザプールに沿って)
- ウェルカムメールなどの送信設定

#### 管理者ユーザーのパスワード設定

```sh
aws cognito-idp admin-set-user-password
```

#### 管理者ユーザー設定の確認

```sh
aws cognito-idp list-users
```

# 解説

## 各コンテナの役割

### aws_local

AWS 環境をローカルで再現する
S3 と Cognito が使えることはわかっている

### bastion

踏み台コンテナ

# 学習

### idp

IdP（Identity Provider）とは、SAML 認証における認証情報の提供者のことである。 組織内で利用している LDAP や Active Directory などの認証サーバと IdP を連携することで、普段利用しているログイン ID とパスワードを使ってクラウドサービスなどへログインすることができる。

# わからなかったこと

## sh ファイルで実行できるようにしてみる

- ここで sh を叩けずにコンテナが落ちたりしてて、tty:ture ではすぐ落ちたのにコマンドに仕込んだら落ちなかったのなんでだろう
- 予想ではコンテナが実行される直前に entypoint が動いたから、その後の処理が流れずに落ちてなかったのかなと予想

## コンテナ名をアンスコで繋いだらネットワークの指定がうまくいかなかった

追記…

## BOOT_FILE_NAME=getUserPoolClient が認証ないと言って怒られる

追記…
