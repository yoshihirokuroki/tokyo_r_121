# Model-Informed Drug Development と R — ICH M15 の時代へ

Tokyo.R #121 応用セッション（2026-07-25）の発表資料リポジトリです。

Quarto + Reveal.js でスライドを生成するqmdファイルと、スライドに含まれるインタラクティブな plotly チャートを生成する R スクリプトを含みます。

---

## リポジトリ構成

```
.
.github/
│   ├── workflows
│       └── publish.yml      # GitHub Actionsの設定ファイル
├── _quarto.yml.             # GitHub Actionsの設定ファイル
├── tokyo_r_121_yoshi.qmd    # メインのスライドソース（Quarto / Reveal.js）
├── dtm_chart.R              # DTM インタラクティブチャート生成関数（plotly）
├── custom.scss              # Reveal.js カスタムテーマ
├── images/                  # スライドで使用する画像
│   ├── Lupusfoto.jpg        #   SLE malar rash（CC BY-SA 4.0、出典は下記）
│   ├── goteti2022_key.png   #   Goteti et al. 論文キービジュアル
│   ├── stan_official.png    #   Stan 公式ロゴ
│   ├── survival.png         #   survival パッケージ hex
│   └── survminer.png        #   survminer パッケージ hex
└── README.md
```

> **Note**: `images/` の一部（論文キービジュアル、hex sticker、malar rash 写真）は、それぞれの出典・ライセンスに従って各自で配置してください。ライセンスの詳細は「画像の出典とライセンス」の節を参照。

---

## ビルド方法

### 必要環境

- [Quarto](https://quarto.org/) 1.4 以降
- R 4.x
- 下記の R パッケージ

### R パッケージ

スライドのレンダリングには以下が必要です。

```r
install.packages(c(
  "plotly",         # インタラクティブチャート（Slide: 地域差の発見）
  "htmlwidgets",    # plotly の HTML 出力
  "DiagrammeR",     # θ 構造図
  "DiagrammeRsvg",  # 構造図の SVG 出力
  "htmltools",
  "ggplot2",        # ミニチャート（popPK/PD, E-R, DTM）
  "ragg"            # macOS/Linux で X11 に依存しないグラフィックデバイス
))
```

> **macOS でのグラフィックデバイスについて**
> 標準の `svg` デバイスは Cairo/X11 に依存し、XQuartz が無いとビルドに失敗します。本プロジェクトは `dev: "ragg_png"` を指定して `ragg` を使うため、XQuartz のインストールは不要です。

### レンダリング

```bash
quarto render tokyo_r_121_yoshi.qmd
```

`embed-resources: true` を指定しているため、生成される `tokyo_r_121_yoshi.html` は単一ファイルで完結し、そのままブラウザで開けます。

### Reveal.js の操作

| キー | 動作 |
|------|------|
| ← → | スライド移動 |
| `s` | プレゼンタービュー（スピーカーノート表示） |
| `f` | フルスクリーン |
| `Esc` | スライド一覧 |

各スライドには日本語のスピーカーノート（発表用スクリプト、約 18 分想定）が `s` キーで表示できます。

---

## インタラクティブチャートについて

`dtm_chart.R` は、SLE 疾患軌跡モデルに基づく plotly チャートを生成する `build_dtm_chart()` 関数を提供します。左パネルに地域別の疾患軌跡、右パネルに組み入れ比率に応じたプラセボ応答率・見かけの治療効果を表示し、下部のスライダーで **Hispanic – Central/South America の組み入れ比率** を操作できます。

スライダーを動かすと、同じ治療薬・同じ試験デザインでも、組み入れ集団の地域構成によって統計的有意性が反転する様子が確認できます。これは「サンプリングが結論を左右する」という本発表の中心的なメッセージを可視化したものです。

`dtm_chart.R` は単体でも実行でき、その場合はスタンドアロンの HTML を出力します。

```bash
Rscript dtm_chart.R
```

> **免責**: チャート中の δ 係数は論文 Table S5 の実値ですが、軌跡・応答率はモデルパラメータに基づく概念的な例示であり、実際の臨床試験データではありません。

---

## 参考文献

- Goteti K, French J, Garcia R, et al. Disease trajectory of SLE clinical endpoints and covariates affecting disease severity and probability of response. *CPT Pharmacometrics Syst Pharmacol.* 2023;12(2):180-195. doi:10.1002/psp4.12888 (PMCID: PMC9931431)
- Goteti K, Garcia R, Gillespie WR, French J, et al. Model-based meta-analysis using latent variable modeling to set benchmarks for new treatments of SLE. *CPT Pharmacometrics Syst Pharmacol.* 2024;13(2):281-295. doi:10.1002/psp4.13083
- ICH M15 Guideline "General Principles for Model-Informed Drug Development" (Step 4 adopted 2026-01-29). EMA/CHMP/ICH/496426/2024, Step 5 発効 2026-07-23. FDA Federal Register 2026-11112 (2026-06-03).

---

## 画像の出典とライセンス

- **Malar rash（`images/Lupusfoto.jpg`）**: Doktorinternet, CC BY-SA 4.0, via Wikimedia Commons — <https://commons.wikimedia.org/wiki/File:Lupusfoto.jpg>
- **論文キービジュアル（`images/goteti2022_key.png`）**: Goteti et al. 2023, *CPT: PSP*（CC BY-NC-ND 4.0）。学術的引用の範囲で使用。再配布時は原著の出典を明記してください。
- **hex sticker（`survival`, `survminer` ほか）**: 各パッケージ／リポジトリのライセンスに従います。
- **Stan ロゴ（`images/stan_official.png`）**: Stan プロジェクト（stan-dev）の公式ロゴ。

各画像は上記ライセンスの範囲でご利用ください。

---

## ライセンス

スライド本文・スピーカーノート・`dtm_chart.R` 等のオリジナル成果物は、特記なき限り作者に帰属します。再利用の際は出典を明記してください。第三者の画像・ロゴ・論文由来の素材は、上記のそれぞれのライセンスが優先されます。

---

## 作者

Yoshihiro "Yoshi" Kuroki — Tokyo.R #121（2026-07-25）
