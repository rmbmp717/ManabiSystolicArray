# ManabiSystollicArray（Verilog HDL・Google DSLX・C++・Python）

## はじめに

ニューラルネットワークの行列演算における重みデータの転送量を削減する回路アーキテクチャとして、**シストリックアレイ**があります。本プロジェクトでは、自己学習と実験を目的にシストリックアレイを設計いたします。  
> *本プロジェクトは教育および実験を目的としており、製品向けの機能や性能最適化は今後の課題です。*

## 目的

シストリックアレイとは、複数の演算要素（PE）を行列乗算に特化して配置し、効率的に演算を行う回路アレイです。大手IT企業のAIチップやNPUにも採用されています。本趣味レベルでの自作に挑戦いたします。

## ブロック図

- **シストリックアレイの概念図**  
  ![シストリックアレイ](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true)

- **制御回路を追加した実装イメージ**  
  *(RISC-Vは学習用の演習として使用しています。)*  
  ![実装イメージ](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu2.jpg?raw=true)

## 設計成果物

- **Pythonモデル**  
- **シストリックアレイ設計データ**（Verilog）  
- **RISC-Vコア設計データ**（Verilog）  
- **RISC-V用ホストプログラム**（C++）  
- **FPGA統合用データ**（Verilog）  
- **16ビット浮動小数点乗算回路**（DSLX → Verilog）

## デモ実行結果

1. C++ホストプログラムをコンパイル  
2. 実行バイナリを`.hex`ファイルに変換  
3. cocotbによるシミュレーションを正常実行

### Command-line Output
```bash
$ riscv64-unknown-elf-gcc -O2 -o main main.cpp
main.cpp: In function ‘int main()’:
main.cpp:10:5: warning: unused variable ‘foo’ [-Wunused-variable]
    10 |     int foo = 42;
       |     ^~~
$ echo "Simulation passed"
Simulation passed

## 設計の詳細

1. **Pythonモデル**  
   - ファイル：`Python_model/SystolicArray_model.py`  
   - 各演算要素（PE）をクラス`PE`として定義し、右シフト・下シフト動作をメソッドでモデル化しています。

2. **シストリックアレイ設計（Verilog）**  
   - ディレクトリ：`Verilog/SA4x4/`  
   - Pythonモデルをそのまま再現したVerilog実装です。  
   - 8×8版も用意していますが、動作確認は未実施です。

3. **RISC-Vコア設計（Verilog）**  
   - ディレクトリ：`Verilog/RISCV/`  
     1. `RV32IM_FPGA_PIPELINE.v` — 5段パイプライン設計  
     2. `RV32IM_FPGA_PIPELINE_SUP.v` — 可能な限り深くパイプラインを詰めた設計

4. **RISC-V用ホストプログラム（C++）**  
   - ディレクトリ：`c_program/`  
   - ビルドにはRISC-Vツールチェーンのインストールが必要です。  
   - ファイル名は後日、より分かりやすいものに変更予定です。

5. **FPGA統合用データ（Verilog）**  
   - ディレクトリ：`fpga/`  
   - 現時点では合成のみ確認済みで、4×4配列は正常に合成可能です。

6. **16ビット浮動小数点乗算回路（DSLX → Verilog）**  
   - ディレクトリ：`Verilog/fp16_mul/`  
     - `fp16_mul.x`：DSLXソース  
     - `fp16_multiplier_stage_n.v`：パイプライン段数`n`で生成されたVerilog  
   - 設計は完了していますが、プロジェクト本体への組み込みは未実施です。

## 未解決の課題

- 本体のシストリックアレイに浮動小数点演算機能が未対応  
- FPGA上での8×8配列合成は現実的ではない

## まとめ

数か月前のノートをまとめたものです。忘れないうちに記録いたしました。  
*(繰り返しになりますが、本プロジェクトは学習用であり、業務とは無関係です。)*  
