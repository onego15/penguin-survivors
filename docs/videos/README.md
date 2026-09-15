# デモ動画の再収録

`penguin-survivors-demo.mp4` は32秒、1280×720、30fps、H.264/AAC。`demo-preview.gif` は冒頭8秒、640×360、10fpsの無音プレビューです。

リポジトリのルートから、Godot 4とFFmpegを使って再生成できます。撮影スクリプトは通常のゲームには組み込まれていません。

```powershell
New-Item -ItemType Directory -Force .godot/demo | Out-Null
godot --path . --script res://tools/record_demo.gd --write-movie .godot/demo/demo.avi --fixed-fps 30 --disable-vsync
ffmpeg -y -i .godot/demo/demo.avi -c:v libx264 -preset medium -crf 24 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart docs/videos/penguin-survivors-demo.mp4
ffmpeg -y -i docs/videos/penguin-survivors-demo.mp4 -t 8 -filter_complex "fps=10,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 docs/videos/demo-preview.gif
```

収録内容：通常戦闘（0〜11秒）、ラスボス登場（11秒〜）、第二形態移行（15秒〜）、大氷震と決戦、祝勝画面（27〜32秒）。経過時間・装備・配置・ゲージ・移動・体力・ボスへのダメージを撮影用に制御しています。
