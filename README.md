# 星灯りの約束

指定された The Spriters Resource の **SNES版 Final Fantasy VI** 素材を使った、Godot製の日本語2D RPGです。町と森を探索し、モグの依頼を受け、星のかけらを取り戻して村へ届ける短編になっています。

**[ブラウザで遊ぶ](https://lockcole6.github.io/starlight-rpg/)** · [GitHub](https://github.com/lockcole6/starlight-rpg)

PCのChrome / Edge / Firefoxでページを開き、ゲーム画面をクリックしてください。キーボード操作用です。日本語フォントを同梱し、Godotやフォントのインストールなしで遊べます。

## 起動

1. Godot **4.7** で、このフォルダーの `project.godot` をインポートします。
2. **F5** でゲーム全体を実行します。
3. タイトルの「はじめから」を選び、広場のモグに話しかけてください。

このPCでは `遊ぶ.cmd` のダブルクリックでも起動できます。Godot本体の場所を変えた場合は、同ファイルの実行ファイルのパスを変更してください。

| 操作 | キー |
|---|---|
| 移動 | 矢印キー / WASD |
| 走る | Shiftを押しながら移動 |
| 話す・調べる・決定・会話送り | Z / E / Enter / Space |
| 記録帳・戻る | Esc / X / C |
| 戦闘コマンド選択 | 上下キー、またはマウス |
| 戦闘の対象選択 | 左右キー / A・D、または敵をクリック |
| 音の切り替え | M / 右上の音ボタン |

## 遊べる内容

- ティナとロックの2人パーティー、4方向アニメーション、仲間の追従。
- 星灯りの村とささやきの森、当たり判定、ミニマップ、場所表示。
- 日本語会話、モグの依頼、道具屋、全回復できる井戸、4個の宝箱。
- 接触式エンカウント、2人のコマンド戦闘、通常の魔物3組とボス1体。
- 攻撃・ファイア・防御・ポーション・逃走。防御は被ダメージ軽減とMP回復。
- 経験値・レベルアップ・所持金・戦闘報酬。全滅時は村で回復して再挑戦。
- 記録帳からセーブ／ロード。クリア時は自動保存し、その後も探索できます。
- オリジナルの簡易BGMと効果音。

依頼は「モグ → 村の東の出口 → 森の北東の守護獣 → モグ」の順に進みます。通常の魔物は回避できます。MPが減ったら防御、HPが減ったらポーションか村の井戸を使ってください。

## Godotで編集する場所

**実行時にUIや地形を組み立てる構成ではありません。** 次のシーンを2D画面で開いて編集できます。各UIの単独シーンはプレビューできるよう表示状態にしてあり、ゲーム開始時の非表示設定は `main.tscn` 側のインスタンスに保存しています。

| 編集対象 | シーン | ノード／リソース |
|---|---|---|
| 全体の構成 | `scenes/main.tscn` | `World`、`Party`、`UI`、`Music`、`SFX` |
| 町の地形・当たり判定 | `scenes/world/town.tscn` | `VillageGround` / `resources/town_tiles.tres` |
| 森の地形 | `scenes/world/forest.tscn` | `ForestGround` / `resources/forest_tiles.tres` |
| 森の木と当たり判定 | `scenes/world/forest.tscn` | `Trees` 以下の各 `Pine_*`、元部品は `scenes/props/pine.tscn` |
| 住人・宝箱・敵・出口の配置 | 各ワールドシーン | `CharactersAndProps` 以下の各ノード |
| 出現地点 | 各ワールドシーン | `PlayerStart`、町の `FromForest`、`AfterDefeat` |
| 色合い・蛍・灯り | 各ワールドシーン | `Lighting/DuskTint`、`Lighting/Fireflies`、`LanternGlow*` |
| 主人公の外見・足元判定・カメラ | `scenes/actors/player.tscn` | `Appearance`、`Feet`、`Camera2D` |
| 仲間の外見・移動 | `scenes/actors/companion.tscn` | `Appearance`、ルートの `Walk Speed` / `Trail Distance` |
| 歩行アニメーション | `resources/terra_frames.tres`、`locke_frames.tres` | `SpriteFrames` の各方向・フレーム・速度 |
| NPCの外見・会話・種別 | `scenes/actors/npc.tscn` とワールド内のインスタンス | `Appearance`、`Marker`、ルートの `Kind` / `Dialogue Text` / `Interaction Range` |
| 宝箱 | `scenes/actors/chest.tscn` | `Appearance`、`Body/Feet` |
| 探索HUD | `scenes/ui/hud.tscn` | `Location`、`Quest`、`Party`、`Minimap` |
| 会話 | `scenes/ui/dialogue.tscn` | `Panel/Text`、`Portrait`、`Speaker` |
| 戦闘 | `scenes/ui/battle.tscn` | `Backdrop` / `BossBackdrop`、`Enemy1` / `Enemy2` / `BossEnemy`、`Hero1` / `Hero2`、`Commands`、`Party` |
| タイトル・記録帳・店・終了画面 | `scenes/ui/` の各シーン | `Title`、`Menu/Card`、`Shop/Card`、`Ending/Card` |
| UIの色・文字 | `resources/ui_theme.tres` | 共通Theme。日本語は `ui_font.tres`、タイトルは `title_font.tres` |

町は、原本のタマサのマップを16×16のタイルに分割したTileMapです。通れる範囲はTileSetのPhysics Layerに保存されています。マップを拡張するときは、見た目のタイルと同時に当たり判定も編集してください。

住人・木などは保存済みシーンのインスタンスです。子ノードの編集を有効にしてあり、ワールド内の `Appearance` なども編集できます。移動や表示切り替えはスクリプト、配置や画面レイアウトはシーンが担当します。敵のHP・攻撃力、クエストの文章などは `scripts/battle.gd` と `scripts/game.gd` にまとまっています。

## セーブ

通常のセーブは `user://starlight_save.json`。このWindows環境では `%APPDATA%/StarlightRPG/starlight_save.json` です。位置・マップ・HP/MP・レベル・所持金・宝箱・討伐状況・依頼の進行を保存します。テストでは別ファイル `tests/output/test_save.json` を使用し、通常のセーブを変更しません。

ブラウザ版ではIndexedDBに保存します。同じブラウザ・同じ公開URLで「つづきから」を選べます。ブラウザのサイトデータを削除するとセーブも消えます。シークレットモードでは永続保存されない場合があります。

## GitHub PagesとWeb書き出し

`main` へpushすると `.github/workflows/deploy-pages.yml` がGodot 4.7で取り込み・動作テスト・Web書き出しを行い、GitHub Pagesにデプロイします。リポジトリの **Settings → Pages → Source** は **GitHub Actions** です。

ローカルでの書き出し（Python 3とGodot 4.7が必要）:

```powershell
./tools/export_web.ps1 -Godot C:\Godot\Godot_v4.7-stable_win64_console.exe -Python python
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

`http://127.0.0.1:8765/` を開いて確認します。HTMLファイルを直接ダブルクリックしても起動しません。Web設定は `export_presets.cfg`、ページの枠・読み込み表示・全画面ボタンは `web/shell.html` で編集できます。Compatibilityレンダラー、スレッド無効、PWA無効の構成で、Pagesに追加HTTPヘッダーは不要です。

書き出し先は `build/web/`。公式テンプレートは `tools/fetch_web_dependencies.py` が `.tools/godot/` に取得します。これらはGit管理対象外です。フォントは `assets/fonts/` にライセンスと一緒に同梱しています。

## 素材と再生成用ツール

原本と出典は `assets/sources/`、ゲーム用に切り出した画像は `assets/art/` に保存しています。詳細は `CREDITS.txt` と `assets/sources/manifest.json` を参照してください。原作素材の権利は各権利者に帰属します。本プロジェクトは非公式ファンデモです。素材の権利を譲渡するものではありません。

`tools/prepare_assets.py` は透過処理・切り出し・簡易音源作成、`tools/build_scenes.py` と `tools/build_world.gd` は制作時のシーン生成用です。**通常の起動・編集には不要です。再実行すると手編集したシーンや素材が上書きされるため、普段はGodotエディタで編集してください。**

## 動作確認

Godot 4.7 / Windows / OpenGL Compatibilityで、起動、45項目の動作テスト、主要8画面の描画を確認しています。レポートは `tests/output/results.json`、実行画像は同フォルダーのPNGです。Web版はChromiumブラウザで日本語表示・会話・記録帳・セーブを確認しています。ゲームパッド・タッチ操作・Safariは確認対象外です。

音声の実聴は未確認です。この検証環境のWASAPI出力は、効果音単体でも再生位置が進まず、終了時に音声リソースの警告が発生しました。`tests/audio_probe.gd` で再現できます。ゲームのBGM・効果音は有効にしてあり、描画テストでは `--audio-driver Dummy` を指定して環境の音声出力を切り離しています。

```powershell
& C:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run.gd
& C:\Godot\Godot_v4.7-stable_win64_console.exe --path . --script tests/run.gd --audio-driver Dummy -- --capture
```
