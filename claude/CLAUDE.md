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

## 人に見せる文章
Slack の投稿・返信、Notion / Confluence の文書、提案・ロードマップなど他人が読む文章を書く・直すときは、
提示する前に `prose-quality` skill を読み、そのチェックリストを黙って通すこと。
呼び出し中のスキルやプロジェクトのテンプレートが出力形式を決めている場合はそちらを優先し、
このスキルは形式の指定がないときの既定として使う。自分しか読まない作業メモは対象外。
