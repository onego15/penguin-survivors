# デモ動画の再収録

2026-09-18更新。`penguin-survivors-demo.mp4` は60秒、1280×720、60fps、H.264/AAC。`demo-preview.gif` はデン登場からの8秒、640×360、30fpsの無音プレビューです。滑らかさと音はMP4で確認してください。

## 収録内容

| 時間 | 内容 |
|---|---|
| 0〜16秒 | 雪原、メガネペンギン、くるくるパール、デンの援護、エンペラー・ブリザード |
| 16〜32秒 | 氷の城、ピンクペンギン、きらきらプリズム、おほしさまメテオ、ラブリー・ブルーム |
| 32〜42秒 | 氷城の梟王・ノクティス登場と第一形態 |
| 42〜54秒 | 第二形態と城の決戦 |
| 54〜60秒 | ペンギンとサポート4匹の祝勝画面 |

本編の描画・攻撃・援護処理を使い、経過時間・装備・配置・ゲージ・移動・体力・ボスへのダメージを撮影用に制御しています。メテオは撮影用に初回の待ち時間を短縮。通常の攻略記録ではありません。終盤とクリアのネタバレを含みます。

## 再生成

GodotのMovie Makerで物理更新と描画を60Hzに固定して収録します。実時間の画面録画や、30fpsからのフレーム複製ではありません。描画が遅くても収録時間を延ばして全フレームを生成します。

```powershell
New-Item -ItemType Directory -Force .godot/demo | Out-Null
godot --path . --script res://tools/record_demo.gd --write-movie .godot/demo/demo.avi --fixed-fps 60 --disable-vsync
ffmpeg -y -i .godot/demo/demo.avi -t 60 -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart docs/videos/penguin-survivors-demo.mp4
ffmpeg -y -ss 2 -i docs/videos/penguin-survivors-demo.mp4 -t 8 -filter_complex "fps=30,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 docs/videos/demo-preview.gif
```

GIFのフレーム時間は仕様上30ms／40msの組み合わせです。16秒地点は別ステージへの意図的なカットです。

## 今回の検証結果

- Godot出力：3600フレーム、60fps、60秒。収録に約73秒をかけ、描画の遅れを動画のコマ落ちにしない方式で生成。
- MP4：全3600フレームを復号、連続同一フレーム0件。1280×720、H.264、音声AACあり。
- 音声：平均−27.6dB、最大−9.8dB。無音トラックではなく、クリッピングなし。
- GIF：240フレーム、8秒、640×360。フレーム時間は30ms／40ms。
- 代表フレームでデンの同行、新武器、両ステージ、必殺技、ノクティスの第二形態、4匹の祝勝画面を確認。

収録中にゲームのスクリプトエラーはありません。実行環境の証明書ストア警告と終了時ObjectDB警告は出ています。
