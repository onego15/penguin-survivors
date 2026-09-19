# デモ動画

2026-09-20再収録。72秒、1280×720、60fps、音声付きMP4です。現在の敵の行動、デンの跳躍援護、進化武器とノクティスの移動氷壁を紹介します。

[動画を開く](penguin-survivors-demo.mp4) · [READMEへ戻る](../../README.md)

## 収録内容

| 時間 | 内容 |
|---|---|
| 0〜18秒 | 雪原の敵・攻撃予告、メガネペンギン、デンの跳躍援護、エンペラー・ブリザード |
| 18〜36秒 | 氷の城、ピンクペンギン、ときめき虹プリズム、メテオ、ラブリー・ブルーム |
| 36〜46秒 | ノクティス登場と第一形態 |
| 46〜66秒 | 第二形態への移行、氷棘の城壁と安全な隙間 |
| 66〜72秒 | ペンギンとサポート4匹の祝勝画面 |

実際のゲームの描画・攻撃・援護処理を使い、装備・進行時刻・敵配置・ゲージ・HP・移動・ボスへのダメージを撮影用に制御しています。メテオの初回待機を短縮し、第二形態の氷壁は撮影時刻に合わせて開始。通常プレイの攻略記録ではありません。終盤・クリア画面のネタバレを含みます。

## 滑らかな収録方法

Godot Movie Makerで物理更新と描画を60Hzに固定します。実時間の画面録画や30fpsの複製ではなく、描画に時間が掛かっても全フレームを生成する方式です。音声はエンジンの出力を使用します。

```powershell
New-Item -ItemType Directory -Force .godot/demo | Out-Null
godot --path . --script res://tools/record_demo.gd --write-movie .godot/demo/demo-new.avi --fixed-fps 60 --disable-vsync
ffmpeg -y -i .godot/demo/demo-new.avi -t 72 -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart docs/videos/penguin-survivors-demo.mp4
ffmpeg -y -ss 3 -i docs/videos/penguin-survivors-demo.mp4 -t 8 -filter_complex "fps=30,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 docs/videos/demo-preview.gif
```

無音GIFは8秒・640×360・30fpsの軽量プレビューです。GIFのフレーム時間は仕様上30／40msの組み合わせです。滑らかさと音はMP4で確認してください。18秒地点はステージを切り替える意図的なカットです。

## 検証結果

- Godot Movie Maker：4,320フレーム、60fps、72秒。生成に約85秒を使用。
- MP4：1280×720、H.264／AAC。全4,320フレームを復号し、連続同一フレームは0件。
- 音声：平均−28.0dB、最大−10.3dB。無音トラックではなく、検出上のクリッピングなし。
- GIF：640×360、240フレーム、8秒。30／40msのフレーム時間。
- 代表フレームでデン、虹プリズム、両ステージ、第二形態の氷壁、4匹の祝勝画面を確認。
- 収録中のスクリプトエラーなし。環境の証明書ストア警告と終了時のObjectDB警告は残っています。

[機械検証の記録](verification.json)
