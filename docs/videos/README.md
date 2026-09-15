# デモ動画の再収録

`penguin-survivors-demo.mp4` は32秒、1280×720、60fps、H.264/AAC。`demo-preview.gif` は冒頭8秒、640×360、30fpsの無音プレビューです。

リポジトリのルートから、Godot 4とFFmpegを使って再生成できます。撮影スクリプトは通常のゲームには組み込まれていません。

```powershell
New-Item -ItemType Directory -Force .godot/demo | Out-Null
godot --path . --script res://tools/record_demo.gd --write-movie .godot/demo/demo.avi --fixed-fps 60 --disable-vsync
ffmpeg -y -i .godot/demo/demo.avi -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart docs/videos/penguin-survivors-demo.mp4
ffmpeg -y -i docs/videos/penguin-survivors-demo.mp4 -t 8 -filter_complex "fps=30,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 docs/videos/demo-preview.gif
```

収録内容：通常戦闘（0〜11秒）、ラスボス登場（11秒〜）、第二形態移行（15秒〜）、大氷震と決戦、祝勝画面（27〜32秒）。経過時間・装備・配置・ゲージ・移動・体力・ボスへのダメージを撮影用に制御しています。

物理更新も60Hzに固定し、元から毎秒60枚を描画します（30fps動画のフレーム複製による変換ではありません）。撮影用の操舵を補間して急な折り返しを抑えています。GIFは時間を1/100秒単位で持つため、30fps相当のフレーム時間は30ms／40msの組み合わせです。本編の滑らかさはMP4で確認してください。

検証：MP4全1920フレームを復号し、連続同一フレーム0件。音声ストリームあり。GIFは240フレーム／8秒、フレーム時間30ms・40ms。最新の必殺技と満タン通知、ラスボス第二形態、祝勝画面を実フレームで確認しました。
