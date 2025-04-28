# ManabiSystollicArray (Verilog HDL & DSLX & C++ & Python)

## Introduction

NeuralNetworkの行列計算の重みのデータ転送量を削減する回路アーキテクチャが存在するそうです。
それが、シストリックアレイです。本プロジェクトではシストリックアレイの自己教育実験目的での設計を行います。
※なお、本プロジェクトは教育・実験目的で作成されています。実際の製品向け機能や高速化は今後の検討課題となります。

## 目的

シストリックアレイ( Systolic array )とは、行列乗算を効率的に行うための演算器アレイです。大手IT企業のAI半導体、NPUなどで使用されています。では、趣味レベルで自作してみよう。

## ブロック図

![シストリックアレイ](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu.jpg?raw=true)
![現実的なシストリックアレイ](https://github.com/rmbmp717/ManabiSystolicArray/blob/main/image/SA_zu2.jpg?raw=true)

## 設計済み成果物

上のシストリックアレイを設計しました。成果物は下記

- Pythonモデル
- シストリックアレイ設計データ（Verilog）
- RISC-V設計データ（Verilog）
- RISC-V用プログラム（C++）
- FPGA用設計データ（Verilog）
- 16bit浮動小数点乗算回路（DSLX→Verilog）

## デモ動作結果

- C++プログラムのコンパイル
- 実行コードをhexファイルに変換
- cocotbシミュレーション実施

## 各設計の詳細

- Pythonモデル <br>
/Python_model/SystolicArray_model.pyclass PEが各プロセッサエレメント、右シフト・下シフトを関数でモデル化しています。

- シストリックアレイ設計データ（Verilog）<br>
/Verilog/SA4x4/のフォルダに格納してあります。基本的には上のPythonモデルをそのまま実行することが仕様です。SA8x8の方は動作確認は未実施です。

- RISC-V設計データ（Verilog）<br>
/Verilog/RISCV/のフォルダに格納してあります。<br>
1. RV32IM_FPGA_PIPELINE.v <br>
2. RV32IM_FPGA_PIPELINE_SUP.v <br>
1は5段パイプライン設計です。2は可能な限りパイプラインを詰めた設計です。

- RISC-V用プログラム（C++）<br>
/c_program/のフォルダに格納してあります。<br>
RISC-V用プログラムのコンパイルにはRISC-Vのツールチェーンをインストールしてください。ファイル名は後でわかりやすいファイル名に変更する予定です。<br>

- FPGA用設計データ（Verilog）
- 16bit浮動小数点乗算回路（DSLX→Verilog）

## 未解決の課題

- 浮動小数点演算には対応していない。
- 8x8のSAはFPGAでの合成が非現実的

## 所感

数か月前のNoteをまとめました。まとめないと忘れてしまいますしね。（再掲）学習用です。仕事は別ですしね。


