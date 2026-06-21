> 🇬🇧 English: [CHANGELOG.md](CHANGELOG.md)

# 変更履歴 (Changelog)

FdiTools の主な変更点をまとめます。書式は
[Keep a Changelog](https://keepachangelog.com/) に準拠し、
バージョンは [セマンティック バージョニング](https://semver.org/) に従います。

## [3.0.1] - 2026-06-18

### 変更 (Changed)
- `bode_fdi` の `'style','band'` が、複素信頼円を**ゲイン軸と位相軸の両方**に陰影表示するようになりました（位相の半幅 `±asin(r/|G|)`、円が原点に達すると `±180°` 全域）。
- `residtest` は残差の自己相関を `xcorr` ではなく FFT で計算するようになり、検証ステップで Signal Processing Toolbox が不要になりました。
- `fdicohere` を書き直し、周期（アンサンブル）コヒーレンスを周期ごとの DFT から計算するようにしました（Signal Processing Toolbox 不要）。`fdicohere(Pest)`（`time2frf_ml` が保存した時系列を使用）または `fdicohere(Pest, dat)`（iodata `dat` を使用）で呼び出せます。

### 後方互換 (v2.1.1, SISO/SIMO)
- `UserData.sGhat` を `UserData.sG` の**非推奨エイリアス**として残しました。
- `bode_fdi(data, noise, option)`（旧来の位置引数／構造体形式）も引き続き受理し、name-value オプションへ変換します。その際 `FdiTools:deprecated` 警告を表示します。`warning('off','FdiTools:deprecated')` で抑制できます。

### ツールボックス (Toolboxes)
- 必須：MATLAB、Control System Toolbox。
- 任意：System Identification Toolbox（`iodata` ↔ `iddata`）、Signal Processing Toolbox（旧来の窓付き推定器と `Tutorial_1` のみ）。

## [3.0.0] - 2026-06-15

オリジナルの FdiTools（v1–v2.1.1）を継承するメジャーアップグレード。

### 追加 (Added)
- `iodata` — System Identification Toolbox なしで動作する、`iddata` 互換の時間領域コンテナ。
- 局所多項式法 (`time2frf_lpm`)：periodic / broadband モード。短く過渡で汚れた記録から FRF を同定。
- MIMO FRF (`time2frf_ml`)：直交多重実験およびジッパー単一実験のマルチサイン。
- ロバスト BLA (`time2bla`)：測定雑音と非線形ひずみを分離。
- `bode_fdi` を再設計（name-value API）＋ `frfconf`：不確かさ付き FRF Bode 線図と、閉形式の信頼区間（Statistics Toolbox 不要）。

### 変更 (Changed)
- FRF 標準偏差のフィールドを `UserData.sGhat` → `UserData.sG` に改名（PS2012 式 2-38）。下記の移行メモを参照。
- `bode_fdi` を位置引数／構造体形式から name-value オプションへ変更。
- MIMO FRF 推定は `iodata` 経由になりました：`time2frf_ml(dat)`。

---

## v2.1.1 から v3.0 への移行

### そのまま動くもの (SISO/SIMO)
以下の v2.1.1 の呼び出しは、シグネチャ・挙動とも変わりません。

| 呼び出し | 備考 |
|---|---|
| `Pest = time2frf_ml(x, y, ms)` | 引き続き `frd` を返す |
| `[y, time] = pretreat(x, nrofs, fs, nroft, trend)` | 行列形式を維持 |
| `ms = multisine(harm, Hampl, options)` | 変更なし |
| `nlsfdi(Pest, FRF_W, n, mh, ml, …)` / `mlfdi(Pest, …)` | 変更なし |
| `btlsfdi(Pest, n, mh, ml, relax, iter, max_err, cORd)` | 変更なし |
| `Pest.freq`, `Pest.resp` | `frd` のプロパティ（`Frequency`/`ResponseData`） |

### 変わった点（と更新方法）

**1. FRF 標準偏差のフィールド**

```matlab
% v2.1.1
sg = Pest.UserData.sGhat;
% v3.0（推奨）
sg = Pest.UserData.sG;
```
`sGhat` は非推奨エイリアスとして残してあるので旧コードも動きます。ただし素の struct フィールドのため、**読み取り時に警告は出ません**。`sG` への移行を推奨します。

**2. Bode 線図 (`bode_fdi`)**

```matlab
% v2.1.1
option.pmin = -180; option.pmax = 180; option.title = 'G';
bode_fdi({Pest}, [freq, noise], option);

% v3.0
bode_fdi(Pest, 'unc', 'sG', 'style', 'band', ...
         'pmin', -180, 'pmax', 180, 'title', 'G');
```
旧形式も引き続き受理されます（`FdiTools:deprecated` 警告付き）。新機能：`'unc'` で不確かさの源（`'sG'`, `'sCR'`, `'FRFn'`, または明示的な `[freq mag]`）を選択でき、`'style','band'` は信頼円をゲインと位相の両方に陰影表示します。

**3. MIMO**

MIMO FRF 推定は `iodata` を使うようになりました。

```matlab
dat  = iodata(output, input, 1/fs, 'Period', nrofs, 'UserData', struct('ms', ms));
Pest = time2frf_ml(dat);     % 直交（多重実験）またはジッパー
```

### 非推奨ポリシー
非推奨の SISO/SIMO エイリアス（`UserData.sGhat`、`bode_fdi` の位置引数／構造体形式）は互換のために残していますが、将来のメジャーバージョンで削除される可能性があります。新規コードでは `UserData.sG` と name-value 形式の `bode_fdi` を使用してください。
