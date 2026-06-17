> 🇬🇧 English: [README.md](README.md)

FdiTools
========

周波数領域システム同定 MATLAB ツールボックス。

> **v3.0** — [HoriFujimotoLab/FdiTools](https://github.com/HoriFujimotoLab/FdiTools)（v1–v2.1.1）
> を継承し大幅にアップグレードした版です。
> オリジナルのリポジトリはそちらで引き続き公開されています。本版では
> `iodata` コンテナ、局所多項式法 (LPM)、および MIMO の FRF/LPM/BLA を追加しています。
> 下記の **3.0 の新機能** を参照してください。

主要参考文献:<br>
- R. Pintelon and J. Schoukens, *System Identification: A Frequency Domain Approach*, 2nd ed., Wiley-IEEE Press, 2012.
- J. Schoukens, R. Pintelon, Y. Rolain, *Mastering System Identification in 100 Exercises*, Wiley-IEEE Press, 2012.

## 3.0 の新機能
- **`iodata`** — System Identification Toolbox **なし**で動作する、`iddata` 互換の時間領域データコンテナ（利用可能な場合は `toIddata`/`fromIddata` で変換）。パイプライン全体の時間領域側を統一します。
- **局所多項式法 (`time2frf_lpm`)** — 過渡（漏れ）をモデル化することで、周期を捨てることなく、短く過渡で汚染された記録から FRF（周波数応答関数）を同定します。2 つのモードがあります。*periodic*（全 P 周期の記録の DFT。非励振のスペクトル線が過渡を担う）と *broadband*（任意の記録）。
- **MIMO FRF 推定 (`time2frf_ml`)** — **直交多重実験**または**ジッパー単一実験**のマルチサインから、伝達行列全体の FRF を推定します。
- **`bode_fdi` を再設計** + **`frfconf`** — 不確かさ（1σ の線または網掛けバンド）と信頼区間バンドの半径（PS2012 式 2-40）を伴う FRF のボード線図。

## インストール
```matlab
addpath(genpath('src'))     % adds src and all sub-packages (incl. @iodata)
```
### 必須ツールボックス
* MATLAB
* Control System Toolbox
### オプション
* System Identification Toolbox — `iodata.toIddata` / `iodata.fromIddata` のためにのみ必要
  （それ以外はすべてこれなしで動作します）
* Signal Processing Toolbox — レガシーの窓掛け推定器
  （`hanning`/`bartlett` を使う `time2frf_h1`、`time2frf_log`）と、
  `Tutorial_1` における `tfestimate` との比較のためにのみ必要。主要パイプライン
  （マルチサイン → `time2frf_ml`/`time2frf_lpm` → パラメトリック推定 → 検証）はこれなしで
  動作します。`residtest` は `xcorr` の代わりに FFT ベースの自己相関を用います。

# 概要

## データ構造
* `iodata` — `iddata` 互換のコンテナ。`OutputData`、`InputData`、`Ts`、
  `Period`、チャネル名、複数実験（セル）、`UserData` を持ちます。
  ```matlab
  dat  = iodata(output, input, 1/fs, 'Period', nrofs, 'UserData', struct('ms', ms));
  dat  = pretreat(dat, 'trans', 1, 'trend', 0);
  Pest = time2frf_ml(dat);          % FRF as an frd
  id   = toIddata(dat);             % -> iddata (needs SI Toolbox)
  ```

## ExcitationDesign
* マルチサイン（線形／準対数グリッド、full/odd/odd-odd、MIMO 直交）
* チャープ／スイープ正弦、PRBS

## NonparametricFRF
* 周期 ML 推定 `time2frf_ml`: $\hat G_{ML}(j\omega)$、標本（共）分散
  $\sigma_U^2,\sigma_Y^2,\sigma_{YU}^2$、FRF の標準偏差 $\sigma_{\hat G}$
  （`sG`; 成分ごとには `sCR`）、ノイズモデル `FRFn`。すべての FRF 推定器
  （`time2frf_ml`/`time2frf_lpm`/`time2bla`）は FRF の標準偏差を `UserData.sG` として提供します。
* **局所多項式法 (LPM)** `time2frf_lpm`: 短い記録に対する過渡の取り扱い。
* **MIMO**: 直交（多重実験）またはジッパー（単一実験）。
* 不確かさ／信頼区間: `bode_fdi`、`frfconf`。

## ParametricEstimation
* 決定論的: 最小二乗、重み付き最小二乗、非線形最小二乗（`lsfdi`、`wlsfdi`、`nlsfdi`）
* 確率的: 最尤、ブートストラップ／一般化 TLS（`mlfdi`、`btlsfdi`、`gtlsfdi`）

## SelectionValidation
3 つの相補的な検定（`residtest`、`costtest`、`chi2test`）:
* **残差白色性** — 残差の*形状*（相関は白色雑音の境界内にあるか）。
* **残差コスト** — 残差の*水準*（雑音フロアまで下がったか。推定器どうしを比較）。
* **χ² モデル化誤差 vs CR 境界** — モデル誤差は各周波数で測定の不確かさ σ_Ĝ を
  下回っているか。

ここでの CR 境界は*測定*の不確かさ（FRF *推定値*分散の下界）であって、残差では
ありません。各図の読み方は
[SISO ステップギャラリー](docs/Examples_Steps_SISO_JP.md)（ステップ 6）で詳しく説明しています。

## Examples
番号付きの `Step_*` スクリプトはモータベンチの標準パイプラインを構成します。`Tutorial_*`
スクリプトは特定の機能に焦点を当てた、自己完結的なデモです。

**結果ギャラリー**（各例の図）:
[SISO Steps](docs/Examples_Steps_SISO_JP.md) ·
[MIMO Steps](docs/Examples_Steps_MIMO_JP.md) ·
[SISO Tutorials](docs/Examples_Tutorials_SISO_JP.md) ·
[MIMO Tutorial](docs/Examples_Tutorials_MIMO_JP.md).
画像は `Examples/export_all_figs` を実行して再生成できます（`savefigs` 経由で
`Examples/plot/` に保存されます）。

| スクリプト | トピック |
|---|---|
| `Step_1_ExcitationDesign` | マルチサイン／PRBS／スイープ正弦の設計 |
| `Step_2_NonparametricFRF` | 周期 ML FRF + 不確かさ／信頼区間バンド |
| `Step_3_NonparametricFRF_LPM_thermal` | 低速な炉（ヒータ→温度）への LPM: 実験時間の短縮 |
| `Step_3_NonparametricFRF_LPM_positioning` | 位置決めステージのベンチマーク（力→速度）への LPM |
| `Step_4_NonlinearDistortions` | 偶／奇の非線形ひずみ検出 |
| `Step_5_ParametricEstimation` | 決定論的・確率的パラメトリック推定 |
| `Step_6_SelectionValidation` | 残差／コスト／カイ二乗による検証 |
| `Step_MIMO1_ExcitationDesign` | MIMO 直交マルチサイン設計 |
| `Step_MIMO2_NonparametricFRF` | 2×2 全 FRF（直交**および**ジッパー）+ 信頼区間バンド |
| `Step_MIMO3_NonparametricFRF_LPM_positioning` | 短い過渡記録からの MIMO LPM（直交、フル分解能） |
| `Step_MIMO4_NonlinearDistortions` | ロバスト MIMO BLA: 雑音 vs 非線形ひずみの水準（`time2bla`） |
| `Step_MIMO5_ParametricEstimation` | MIMO 構造化モーダル同定（`frf2modal`） |
| `Step_MIMO6_SelectionValidation` | モード数の選択 + モーダルモデルの残差検証 |
| `Tutorial_1_*` | ランダム／チャープ／qlog 励振のチュートリアル |
| `Tutorial_2_iterative` | 反復的（逆 S/N）実験設計 |
| `Tutorial_3_nonlinear_*` | 非線形ひずみ解析 |
| `Tutorial_4_MIMO` | MIMO FRF（直交／ジッパー）+ 構造化モーダル同定 |

# 例のプロット
2 質量系のセットアップ

<img src="Examples/plot/twomass.jpg?raw=true" width="400">

## ExcitationDesign
<img src="Examples/plot/1_Multisine.png?raw=true" width="600">

## NonparametricFRF
<img src="Examples/plot/2_FRFest.png?raw=true" width="600">

## NonlinearDistortions
<img src="Examples/plot/3_NL.png?raw=true" width="600">

## ParametricEstimation
<img src="Examples/plot/4_deterministic.png?raw=true" width="600">

<img src="Examples/plot/4_stochastic.png?raw=true" width="600">
