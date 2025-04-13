# フォレストプロットの改良版：行名、推定値、プロットが重ならないように配置

# 必要なパッケージを読み込み
library(netmeta)
library(meta)
library(dplyr)
library(ggplot2)

# 保存されたデータを読み込み
load("nma_results.RData")

# サブグループごとの結果を抽出して整形
treatments <- c()
settings_list <- c()
effects <- c()
lower_ci <- c()
upper_ci <- c()
ref_treatments <- c() # 参照治療を追跡するための配列

# 参照治療
reference_treatment <- "No Intervention"

# 各サブグループの結果を処理
for (s in c("Primary care", "Emergency department", "College health clinic")) {
  # 対応するオブジェクト名を構築
  nma_obj_name <- paste0("nma_", tolower(gsub(" ", "", s)))
  
  # オブジェクトが存在するか確認
  if (exists(nma_obj_name)) {
    nma_s <- get(nma_obj_name)
    
    # 参照グループが存在するか確認
    if (reference_treatment %in% nma_s$trts) {
      ref_idx <- which(nma_s$trts == reference_treatment)
      
      # 各治療法と参照グループの比較結果を抽出
      for (i in 1:length(nma_s$trts)) {
        if (i != ref_idx) {
          treatments <- c(treatments, nma_s$trts[i])
          settings_list <- c(settings_list, s)
          ref_treatments <- c(ref_treatments, reference_treatment) # 参照治療を追加
          
          # 変量効果モデルの結果を使用
          if (nma_s$random) {
            effects <- c(effects, nma_s$TE.random[ref_idx, i])
            lower_ci <- c(lower_ci, nma_s$lower.random[ref_idx, i])
            upper_ci <- c(upper_ci, nma_s$upper.random[ref_idx, i])
          } else {
            effects <- c(effects, nma_s$TE.fixed[ref_idx, i])
            lower_ci <- c(lower_ci, nma_s$lower.fixed[ref_idx, i])
            upper_ci <- c(upper_ci, nma_s$upper.fixed[ref_idx, i])
          }
        }
      }
    } else if (length(nma_s$trts) > 0) {
      # 参照グループが存在しない場合は、最初の治療法を参照として使用
      ref_idx <- 1
      for (i in 2:length(nma_s$trts)) {
        treatments <- c(treatments, nma_s$trts[i])
        settings_list <- c(settings_list, s)
        ref_treatments <- c(ref_treatments, nma_s$trts[ref_idx]) # 実際の参照治療を追加
        
        # 変量効果モデルの結果を使用
        if (nma_s$random) {
          effects <- c(effects, nma_s$TE.random[ref_idx, i])
          lower_ci <- c(lower_ci, nma_s$lower.random[ref_idx, i])
          upper_ci <- c(upper_ci, nma_s$upper.random[ref_idx, i])
        } else {
          effects <- c(effects, nma_s$TE.fixed[ref_idx, i])
          lower_ci <- c(lower_ci, nma_s$lower.fixed[ref_idx, i])
          upper_ci <- c(upper_ci, nma_s$upper.fixed[ref_idx, i])
        }
      }
    }
  }
}

# データが抽出できたか確認
if(length(treatments) > 0 && length(treatments) == length(settings_list) &&
   length(treatments) == length(effects) && length(treatments) == length(lower_ci) &&
   length(treatments) == length(upper_ci) && length(treatments) == length(ref_treatments)) {
  
  # データフレームを作成
  forest_data <- data.frame(
    treatment = treatments,
    ref_treatment = ref_treatments, # 参照治療を追加
    setting = settings_list,
    effect = effects,
    lower = lower_ci,
    upper = upper_ci,
    stringsAsFactors = FALSE
  )
  
  # 設定ごとに色を割り当て
  setting_colors <- c(
    "Primary care" = "black",
    "Emergency department" = "blue",
    "College health clinic" = "red"
  )
  
  # 設定ごとに形状を割り当て
  setting_pch <- c(
    "Primary care" = 15, # 四角
    "Emergency department" = 16, # 丸
    "College health clinic" = 17 # 三角
  )
  
  # 比較の種類を作成
  forest_data$comparison_type <- paste(forest_data$treatment, "vs", forest_data$ref_treatment)
  
  # 比較の種類に基づいてソート順を定義
  comparison_order <- c(
    "BLC vs No Intervention",
    "BA vs No Intervention",
    "PIL vs No Intervention",
    "BLC vs PIL",
    "BLC vs BA",
    "BA vs PIL"
  )
  
  # 比較の種類に基づいてソート順を割り当て
  forest_data$sort_order <- match(forest_data$comparison_type, comparison_order)
  
  # 比較の種類でソート、次にサブグループでソート
  forest_data <- forest_data[order(forest_data$sort_order, forest_data$setting), ]
  
  # 改良版フォレストプロットを作成
  pdf("forest_plot_subgroups_alt.pdf", width = 20, height = 10)
  
  # プロットの余白を大幅に調整（テキストとプロット領域を完全に分離）
  # 左側の余白を特に広くして行名と推定値が重ならないようにする
  par(mar = c(5, 25, 4, 14), oma = c(0, 0, 2, 0))
  
  # プロット領域の設定
  x_min <- -100
  x_max <- 150
  
  # プロット領域外にもテキストを描画できるようにする
  par(xpd = TRUE)
  
  # フォレストプロットの作成
  # まずプロットエリアを設定 - X軸の範囲を調整し、枠を削除
  plot(NA, NA, xlim = c(x_min, x_max), ylim = c(0.5, nrow(forest_data) + 2.5),
       xlab = "", ylab = "", yaxt = "n", xaxt = "n", bty = "n",
       main = "")
  
  # グリッド線
  abline(v = 0, lty = 2)
  abline(v = seq(x_min, x_max, by = 50), lty = 3, col = "lightgray")
  
  # 比較の種類の区切り線を追加
  prev_comparison <- NULL
  for (i in 1:nrow(forest_data)) {
    if (is.null(prev_comparison) || prev_comparison != forest_data$comparison_type[i]) {
      if (!is.null(prev_comparison)) {
        abline(h = i - 0.5, lty = 3, col = "darkgray", lwd = 1.5)
      }
      prev_comparison <- forest_data$comparison_type[i]
    }
  }
  
  # X軸ラベルと目盛り
  axis(1, at = seq(x_min, x_max, by = 50))
  mtext("Mean Difference", side = 1, line = 3, cex = 1.1)
  
  # 効果の方向性を示す注釈
  mtext("Favors Reference", side = 1, line = 1.5, at = -75, cex = 1.0)
  mtext("Favors Treatment", side = 1, line = 1.5, at = 125, cex = 1.0)
  
  # 各行のラベルとエフェクトサイズをプロット - 重ならないように位置を調整
  for (i in 1:nrow(forest_data)) {
    # 設定に基づいて色と形状を選択
    current_color <- setting_colors[forest_data$setting[i]]
    current_pch <- setting_pch[forest_data$setting[i]]
    
    # 行名 - 左端に配置（位置を-250に変更して左に寄せる）
    text(-250, i, paste0(forest_data$treatment[i], " vs ", forest_data$ref_treatment[i]),
         adj = 0, cex = 0.9)
    
    # 推定値 - 行名と重ならないように配置（位置を-120に変更）
    text(-120, i, sprintf("%.2f [%.2f; %.2f]",
                        forest_data$effect[i],
                        forest_data$lower[i],
                        forest_data$upper[i]),
         adj = 1, cex = 0.9)
    
    # エフェクトサイズと信頼区間 - プロット領域内に表示
    points(forest_data$effect[i], i, pch = current_pch, cex = 1.2, col = current_color)
    lines(c(forest_data$lower[i], forest_data$upper[i]), c(i, i),
          lwd = 2, col = current_color)
  }
  
  # タイトルを追加
  title(main = "Subgroup Analysis – Mean Difference",
        line = 1, cex.main = 1.3, font.main = 2)
  
  # 統計情報のラベル - "MD"をプロット領域の上部に配置
  mtext("MD", side = 3, line = -1.5, at = 0, cex = 0.9)
  
  # 凡例を改善 - 位置を調整して重ならないようにする（枠なし）
  legend("topright",
         legend = c("Primary care", "Emergency department", "College health clinic"),
         pch = c(15, 16, 17),
         col = c("black", "blue", "red"),
         cex = 1.0,
         pt.cex = 1.5,
         title = "Settings",
         bg = "white",
         box.lty = 0, # 枠を削除
         inset = c(0.01, 0.05)) # 内側へのオフセットを調整
  
  dev.off()
  
  cat("改良版フォレストプロットを作成しました。forest_plot_subgroups_alt.pdfを確認してください。\n")
} else {
  cat("データの抽出に問題があり、フォレストプロットを作成できませんでした。\n")
  cat("抽出されたデータ長: treatments =", length(treatments),
      ", settings =", length(settings_list),
      ", effects =", length(effects), "\n")
}