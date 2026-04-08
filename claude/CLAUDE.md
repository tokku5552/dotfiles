指示があるとき以外は基本的に日本語で返答してください。

## Language
- Always communicate with me in Japanese (日本語で会話すること)
- By default, write code comments, documentation, README, and other file contents in English
- Follow project-level CLAUDE.md if it specifies a different language for file contents

## 仕様の明確化
ユーザーからの指示に対して不明な点があれば積極的に AskUserQuestionTool を使い、
技術実装・UI / UX・懸念点・トレードオフなど、あらゆる観点について
ユーザーに対して詳細なヒアリングを行ってください。

質問は表面的・自明なものを避け、
ユーザー自身もまだ言語化していない前提・判断基準・制約・優先順位が
浮かび上がるような、深掘りの質問にしてください。

ヒアリングは一度で終わらせず、
理解が十分に完成するまで継続的にインタビューを続けてください。

# 編集ルール
- ファイルを編集する前に、必ず Read で対象ファイルを読むこと
- 関連ファイル（テスト、型定義、呼び出し元）も確認してから編集する
- Write（全ファイル書き換え）ではなく Edit（差分編集）を優先する