# 武器の名前と見た目

[README](../README.md) · [性能と成長](weapons.md) · [ステージ所属](stages.md)

23武器の攻撃性能・成長・ステージ所属は維持し、名前と見た目を整理しました。**凍結はアイスキャンディだけ**。くるくるパールは接触攻撃で、防御・ダメージ軽減はありません。

![23武器の装備モデル](screenshots/weapon-models-23.png)

## 名前の対応と個別の実画面

| 以前の名前 | 現在の名前 | 実画面 |
|---|---|---|
| 氷ブラスター | こおりのポップガン | [攻撃を見る](screenshots/weapon-style-frost.png) |
| ハートの波動 | ときめきハート | [攻撃を見る](screenshots/weapon-style-heart.png) |
| 羽根ショット | ふわふわ羽根ショット | [攻撃を見る](screenshots/weapon-style-fan.png) |
| つららランス | すいすいつらら | [攻撃を見る](screenshots/weapon-style-spear.png) |
| おひさまロッド | ぽかぽかおひさま | [攻撃を見る](screenshots/weapon-style-ember.png) |
| かみなりベル | ぴかぴかベル | [攻撃を見る](screenshots/weapon-style-lightning.png) |
| 真珠のまもり | くるくるパール | [攻撃を見る](screenshots/weapon-style-orbit.png) |
| 氷河のチャイム | ひんやりチャイム | [攻撃を見る](screenshots/weapon-style-nova.png) |
| どんぐりボム | ころころどんぐり | [攻撃を見る](screenshots/weapon-style-mine.png) |
| おさかなブーメラン | おかえりおさかな | [攻撃を見る](screenshots/weapon-style-boomerang.png) |
| 星ふるスノードーム | こなゆきドーム | [攻撃を見る](screenshots/weapon-style-storm.png) |
| オーロラリボン | ゆらゆらリボン | [攻撃を見る](screenshots/weapon-style-whip.png) |
| ほのおのスケート | あつあつスケート | [攻撃を見る](screenshots/weapon-style-trail.png) |
| 氷玉ビリヤード | ころりんアイスボール | [攻撃を見る](screenshots/weapon-style-bounce.png) |
| ゆきだるま砲台 | ゆきだるまシューター | [攻撃を見る](screenshots/weapon-style-turret.png) |
| ミツバチロケット | ぶんぶんロケット | [攻撃を見る](screenshots/weapon-style-seeker.png) |
| 極光プリズム | きらきらプリズム | [攻撃を見る](screenshots/weapon-style-beam.png) |
| しっぽの散弾 | しっぽのクラッカー | [攻撃を見る](screenshots/weapon-style-rear_fan.png) |
| うしろ花火 | ぱちぱち花火 | [攻撃を見る](screenshots/weapon-style-rear_bomb.png) |
| ちゅるちゅるおうどん | 変更なし | [攻撃を見る](screenshots/weapon-style-udon.png) |
| ぱたぱた扇風機 | 変更なし | [攻撃を見る](screenshots/weapon-style-gust.png) |
| ひえひえアイスキャンディ | 変更なし | [攻撃を見る](screenshots/weapon-style-popsicle.png) |
| おほしさまメテオ | 変更なし | [攻撃を見る](screenshots/weapon-style-starfall.png) |

![効果が分かる選択画面](screenshots/weapon-style-choices.png)

## 見分け方

- **装備と攻撃**：装備の飾りは固定位置で軽く上下するだけ。パールだけが周回して接触ダメージを与えます。手持ち・どんぶり・首振り扇風機の配置は従来どおりです。
- **前方と後方**：羽軸のある羽根は前方へ、クラッカーの星形紙片は背後へ飛びます。
- **ベルとチャイム**：稲妻飾りの丸いベルはランダム落雷。長さの違う氷の管3本は周囲へ冷気の波を広げます。
- **雪と星**：こなゆきドームは固定地点の雪片による継続攻撃。メテオは巨大な星が1回着弾します。
- **雪だるま**：にんじんの鼻とは別の砲口が敵へ向き、雪玉を撃ちます。
- **どんぐり**：足元へ短く転がるのは表示だけ。待ち伏せ爆弾の判定位置は固定で、移動し続けません。
- **氷と凍結**：氷粒やつららは命中すると砕けます。敵全体が氷色になり結晶に包まれるのはアイスキャンディの凍結状態です。

![前方の羽根](screenshots/weapon-style-fan.png)
![後方の星形紙片](screenshots/weapon-style-rear_fan.png)
![16武器と敵予告](screenshots/weapon-style-overlap.png)

Godotで `scenes/weapon_gallery.tscn` を開きF6で装備モデルを一覧できます。キャラクターのモデル一覧にも武器一覧ボタンを追加しました。個別の攻撃はサンドボックスで試せます。
