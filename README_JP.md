# ManabiSystollicArray（Verilog HDL・Google DSLX・C++・Python）

## はじめに
ニューラルネットワークの行列演算における重みデータの転送量を削減する回路アーキテクチャとして **シストリックアレイ** があります。  
本プロジェクトでは、自己学習と実験を目的にシストリックアレイを設計いたします。  
> *本プロジェクトは教育および実験を目的としており、製品向けの機能や性能最適化は今後の課題です。*

## 目的
シストリックアレイは、複数の演算要素（PE）を行列乗算に特化して配置し、データをパイプライン状に流すことで高いスループットを実現する回路アレイです。  
大手 IT 企業の AI チップや NPU にも採用されていますが、ここでは趣味レベルで自作に挑戦します。

## ブロック図
| | |
|---|---|
| **シストリックアレイの概念図** | **制御回路を追加した実装イメージ**<br>*RISC-V は学習用の演習として使用しています。* |
| <img src="https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true" alt="Conceptual Diagram" width="300"/> | <img src="https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu2.jpg?raw=true" alt="Implementation Diagram" width="300"/> |

## 設計成果物
- **Python モデル**  
- **シストリックアレイ RTL**（Verilog）  
- **RISC-V コア RTL**（Verilog）  
- **RISC-V 用ホストプログラム**（C++）  
- **FPGA 統合用データ**（Verilog）  
- **16 ビット浮動小数点乗算回路**（DSLX → Verilog）

## デモ実行結果
1. C++ ホストプログラムをコンパイル  
2. 実行バイナリを `.hex` 形式に変換  
3. `cocotb` でシミュレーションを実行  

### Command-line Output
```bash
1450.00ns INFO  cocotb  C_tmp = [  0   0   0 114]
1450.00ns INFO  cocotb  Updated HW result during step row_i=6 =
                       [[181  78  97  90]
                        [ 84 103  72  33]
                        [114  36  80  79]
                        [212 110 136 114]]
=============== calc loop end ===============
=============== Output data ================
1650.00ns INFO  cocotb  Updated HW result during step row_i=6 =
                       [[181  78  97  90]
                        [ 84 103  72  33]
                        [114  36  80  79]
                        [212 110 136 114]]
1650.00ns INFO  cocotb  Test Passed! HW result matches Python model.
1650.00ns INFO  cocotb.regression  test_systolic_array passed
```

## シミュレーション波形
波形でも行列積の出力が正しいことを確認しました。  
![シミュレーション波形](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_wave.jpg?raw=true)

## 設計の詳細
1. **Python モデル**  
   `Python_model/SystolicArray_model.py` — 各 PE の右シフト・下シフト動作を関数でモデル化  
2. **シストリックアレイ RTL**  
   `Verilog/SA4x4/` — Python モデルを忠実に実装（8×8 版は未検証）  
3. **RISC-V コア RTL**  
   `Verilog/RISCV/`  
   - `RV32IM_FPGA_PIPELINE.v` — 5 段パイプライン  
   - `RV32IM_FPGA_PIPELINE_SUP.v` — 深パイプライン版  
4. **ホストプログラム（C++）**  
   `c_program/` — RISC-V ツールチェーンでビルド（ファイル名は後日整理予定）  
5. **FPGA 統合用データ**  
   `fpga/` — 4×4 配列で合成確認済み  
6. **16 ビット FP 乗算器**  
   `Verilog/fp16_mul/`  
   - `fp16_mul.x` — DSLX ソース  
   - `fp16_multiplier_stage_n.v` — パイプライン段数 *n* の Verilog  
   （本体への組み込みは未実施）

## 未解決の課題
- 現状のシストリックアレイは整数演算のみ対応  
- 8×8 配列は対象 FPGA ではリソース不足で非現実的  

## まとめ
数か月前のノートを統合し、忘れないうちに記録しました。  
**設計期間:** 2 時間 × 10 日  

> *本プロジェクトは学習目的であり、業務とは無関係です。*
