# Inv1_cognito

# 実現したいこと

-  Cognitoをローカルで再現し、Nextから認証をする
   -  認証をしたことを確認するためにNext側でログイン画面を設置
   -  ログインすると見れるダッシュボードを用意したい


# やらないといけないこと

- [x] Cognitoのコンテナを用意
- [x] Cognito(AWS環境)を操作する踏み台コンテナを用意
  - [ ] Nextのコンテナからでもいいかも？
- [ ] 認証できるかを試す
- [ ] Nextでログイン画面を用意
- [ ] Nextで認証画面を用意

# 使い方やコマンド

### 踏み台コンテナ経由でAWSコマンドの流し込み

```
dcr -e BOOT_FILE_NAME=XXXXXXX bastion
```

XXXXXXに該当するコマンドが打てるようになった

# 実装

### Cognitoのコンテナを用意

https://ma-vericks.com/blog/build-cognito-in-docker/

この記事丸パクリでコンテナを作成

### 踏み台コンテナを用意

AWS CLIが叩けるコンテナを用意したかったので公式からパクる

https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-docker.html


### 立ち上げ

moto server側は立ち上がったが、aws cliの方がエラー吐いて死んだ

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

awsを頭につけてたのが悪かったみたい


### shファイルで実行できるようにしてみる

長いコマンドを打つときにdocker-comopose runで実行するの嫌やからshを書いてそれに実行させたい

普通にdcrの引数にしてshを作って叩いたら落ちた

記事に書いてあるとおり下記をdockerfileに書いたらうまく呼び出せた

```
entrypoint: sh -c "chmod +x /bastion/bash/sample.sh && /bastion/bash/sample.sh && tail -f /dev/null"
```

よくわからんからおさらいもかねて記載

この`entrypoint`の設定は、Dockerコンテナが起動したときに実行されるコマンドを指定しています。具体的には以下のような意味があります：

- `sh -c "..."`：シェルを起動し、ダブルクォーテーション内のコマンドを実行します。
- `chmod +x /bastion/bash/sample.sh`：`/bastion/bash/sample.sh`というスクリプトに実行権限を付与します。これにより、このスクリプトを実行可能な状態にします。
- `/bastion/bash/sample.sh`：上記で実行権限を付与したスクリプトを実行します。
- `&&`：左側のコマンドが成功した場合（終了ステータスが0の場合）に、右側のコマンドを実行します。これにより、複数のコマンドを一連の処理として順番に実行することができます。
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

awsの設置値を戻す

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


networksに知らないのがついてる

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
- Lambdaの連携設定
- emailと電話番号の検証
- ユーザIDをどれにするか指定
- SMSかメールでのか検証連絡
- MFA対応
- パスワード忘れた時の対応


#### アプリクライアントの作成

```sh
aws cognito-idp create-user-pool-client
```

アプリがアクセスするエンドポイントを作成する


#### 管理者ユーザーの作成

```sh
aws cognito-idp admin-create-user
```

これはadminがユーザを登録する機能と考えていい
クライアント経由でアカウントを登録するからと認識した

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

AWS環境をローカルで再現する
S3と Cognitoが使えることはわかっている


### bastion

踏み台コンテナ


# 学習

### idp

IdP（Identity Provider）とは、SAML認証における認証情報の提供者のことである。 組織内で利用しているLDAPやActive Directoryなどの認証サーバとIdPを連携することで、普段利用しているログインIDとパスワードを使ってクラウドサービスなどへログインすることができる。


# わからなかったこと


- shファイルで実行できるようにしてみる
  - ここでshを叩けずにコンテナが落ちたりしてて、tty:tureではすぐ落ちたのにコマンドに仕込んだら落ちなかったのなんでだろう
  - 予想ではコンテナが実行される直前にentypointが動いたから、その後の処理が流れずに落ちてなかったのかなと予想

- コンテナ名をアンスコで繋いだらネットワークの指定がうまくいかなかった
  - 