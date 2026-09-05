# Runbook: Claude Code の設定を PC ごとに管理する

`~/.claude/settings.json` を「全 PC 共通のベース + その PC 固有のオーバーレイ」から
生成し、Claude Code 自身の書き戻し（ドリフト）を検知・振り分けるための運用手順。

仕組みの概要は [README.md](../README.md#claude-code-の設定pc-ごとの差分) を参照。
この文書は**実際に手を動かすときの手順書**。

| ファイル | 追跡 | 役割 |
| --- | --- | --- |
| `claude/settings.json` | される | 全 PC 共通のベース |
| `claude/settings.local.json` | されない | この PC 固有のオーバーレイ |
| `~/.claude/settings.json` | — | 生成物。Claude Code が読み**書き**する |
| `~/.claude/.settings.snapshot.json` | — | 前回生成した内容。3-way マージの共通祖先 |

---

## 1. 初回移行（PC ごとに 1 回だけ）

> **なぜ手順が要るか**
> 移行前は `~/.claude/settings.json` が `claude/settings.json` への symlink なので、
> `live` と `base` が**同じファイル**になっている。この状態で install しても sync.sh に
> は差分が見えず、その PC 固有の設定が追跡ファイルに残り続ける。
> **先に symlink を切って 2 つを別のファイルにする**のが移行の本体。
>
> さらに `git pull` は sync.sh がその PC に届く**前に**ライブ設定を上書きする。
> だから退避が最初に来る。

Claude Code は**全部終了してから**始めること。起動中のセッションは古い読み取り結果で
ファイル全体を上書きするため、マージ結果が巻き戻る。

### 1-1. ライブ設定を退避する（最初にやる）

```bash
cp -L ~/.claude/settings.json /tmp/live-backup.json && jq -e 'type=="object"' /tmp/live-backup.json
```

`-L` は symlink の**中身**をコピーするため。この時点ではまだ symlink なので必須。

### 1-2. 作業ツリーを片付ける

まずブランチと未コミット差分を見る。作業用ブランチに乗ったままの PC がある。

```bash
cd ~/dotfiles && git branch --show-current && git status --short
```

`claude/settings.json` の差分は Claude Code が symlink 経由で書き戻したもの。
共通設定として意図的に入れたものでなければ捨てる（1-1 で退避済み、1-6 で overlay に入る）。

```bash
cd ~/dotfiles && git checkout claude/settings.json
```

**捨てるのは pull より先。** 順序を逆にすると、ベース側が同じファイルを触っていたときに
pull が中断する。他のファイル（`ccstatusline/settings.json` など）にも同種の書き戻しが
乗っていることがある。中身を見て、要らなければ同様に捨てる。

### 1-3. ベースを取り込む

main にいなければ戻ってから pull する。

```bash
cd ~/dotfiles && git switch main && git pull
```

### 1-4. symlink を切って実ファイルにする

```bash
rm ~/.claude/settings.json && cp /tmp/live-backup.json ~/.claude/settings.json
```

### 1-5. 生成する

```bash
bash ~/dotfiles/claude/install.sh
```

初回は共通祖先が `{}` なので、ベースとライブで**値が違う**キーは競合として報告され、
**何も書かれずに exit 3** で止まる。2 台目以降ではほぼ必ず起きる（`effortLevel` や
`enabledPlugins` は PC ごとに違うため）。報告内容を見て、その PC の値を採用してよければ:

```bash
bash ~/dotfiles/claude/install.sh --prefer-local
```

> `--prefer-local` で解決したキーは**その場では永続化されない**（ライブには反映されるが
> base にも overlay にも書かれない）。次の 1-6 で通常のドリフトとして拾われるので、
> 1-6 まで進めれば恒久化される。

### 1-6. ドリフトを振り分ける

```bash
bash ~/dotfiles/claude/sync.sh --apply
```

`LOCAL_KEYS` に載っているキーは `claude/settings.local.json` へ、それ以外は共通の
`claude/settings.json` へ書き戻される。**振り分け先は必ず画面に出る**ので、想定と違えば
後から手で直す。

### 1-7. 確認

**ここが判断ポイント。** 共通ベースに何が入ろうとしているかを必ず目で見る。

```bash
cd ~/dotfiles && git diff claude/settings.json
```

残ってよいのは「全 PC で共有したい変更」だけ。`theme` / `effortLevel` / `advisorModel` /
`agentPushNotifEnabled` / `enabledPlugins` / `extraKnownMarketplaces` がここに出ていたら
振り分けが誤っている。`claude/sync.sh` の `LOCAL_KEYS` にそのキーを 1 行足し、
`git checkout claude/settings.json` してから 1-6 をやり直す。

```bash
cd ~/dotfiles && jq . claude/settings.local.json
```

オーバーレイにその PC 固有のキーが入っていること。

```bash
bash ~/dotfiles/claude/sync.sh
```

`in sync.` / exit 0 になること。内容が落ちていないこと
（`diff` はシェルの alias/function に潰されることがあるのでフルパスで叩く）:

```bash
/usr/bin/diff <(jq -S . /tmp/live-backup.json) <(jq -S . ~/.claude/settings.json) && echo "no loss"
```

ガードレールが生きていること:

```bash
jq -e '.permissions.deny|length>0' ~/.claude/settings.json \
  && jq -e '[.hooks.PreToolUse[].hooks[].command]|any(test("deny-check"))' ~/.claude/settings.json \
  && echo "guardrails ok"
```

最後に**実セッションでの確認**。ここだけは自動テストで代替できない
（Claude Code が生成ファイルを実際にロードしたことの唯一の証明）。

- `claude` を起動して Bash を 1 回実行 → `tail -2 ~/.claude/audit.log` に出るか
- `/config` で theme を変えて終了 → `bash ~/dotfiles/claude/sync.sh` が
  `theme -> overlay` と報告するか

**ここまで通るまで `/tmp/live-backup.json` は消さないこと。** 移行前の設定はこれが
唯一のコピー。うまくいかなければ 3-3 のロールバックで symlink 方式に戻せる。

---

## 2. 日常運用

### 2-1. PR を出す前

Claude Code が書き戻した差分を、共通側とこの PC 側に振り分ける。

```bash
bash ~/dotfiles/claude/sync.sh
```

差分があれば exit 3。振り分けて確認:

```bash
bash ~/dotfiles/claude/sync.sh --apply && cd ~/dotfiles && git diff claude/settings.json
```

**`git diff` は必ず見る。** 共通ベースに入ってよいものだけが残っているか確認する。
想定外のキーが `base` に向かっていたら、そのキーを `claude/sync.sh` の `LOCAL_KEYS`
に 1 行足して `--apply` をやり直す。

何が起きるか先に見たいだけなら:

```bash
bash ~/dotfiles/claude/sync.sh --apply -n
```

### 2-2. 他の PC の変更を取り込む

```bash
cd ~/dotfiles && git pull && bash ~/dotfiles/claude/install.sh
```

自分のドリフトと他 PC の変更の**両方**が保持される。同じキーを両方が別々に変えていた
場合だけ競合になり、何も書かずに止まる（→ 3-2）。

---

## 3. トラブルシュート

### 3-1. exit code

| code | 意味 | 対処 |
| --- | --- | --- |
| 0 | 正常 / 差分なし | — |
| 1 | 使用法エラー、`jq` が無い、ベースが見つからない | メッセージ通り |
| 2 | 入力が JSON オブジェクトでない | 壊れたファイルを直す。**生成物は書かれていない** |
| 3 | `--report` は差分あり / `--merge`・`--apply` は競合 | → 3-2 |
| 4 | 安全条件違反（deny が空、deny-check hook が無い） | ベースかオーバーレイを直す。**何も書かれていない** |

exit 3 と 4 は「壊れた」のではなく「**危ないので書かなかった**」状態。
`~/.claude/settings.json` は手つかずなので、その PC はそのまま動き続ける。

### 3-2. 競合が出た

同じキーをこの PC と他の PC が別々に変えたときに出る。ancestor / local / upstream の
3 つが表示されるので、どれが正しいか決める。

- **この PC の値でよい** → `bash ~/dotfiles/claude/sync.sh --merge --prefer-local`
- **他の PC の値でよい** → `claude/settings.json` か `claude/settings.local.json` を
  手で直してから `--merge`。ベースを直すほうが「なぜそうしたか」が git に残る

`--prefer-local` で解決したキーは**永続化されない**（ライブには反映されるがベースにも
オーバーレイにも書かれない）。意図的な仕様: 競合の片側を黙ってベースに書き込むのは、
この仕組みが防ごうとしている lost update そのものだから。恒久的にしたいなら手で書く。

### 3-3. ロールバック

移行前の symlink 方式に戻すだけ。

```bash
rm ~/.claude/settings.json && ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
```

`~/.claude/.settings.snapshot.json` は残しても害はないが、消せば次回は初回移行扱いに戻る。

### 3-4. `~/.claude/settings.json` を手で編集してしまった

編集内容はドリフトとして扱われるので失われない。`sync.sh --apply` で拾って正しい側へ
振り分ける。ただし**恒久的な変更はベースかオーバーレイに書くのが正しい**。生成物は
マージのたびに上書きされる。

### 3-5. `git clean -xdf` をやってしまった

`claude/settings.local.json` は**復旧不能**（`zsh/.zshrc.local` と同じ扱い）。
`~/.claude/` 配下の生成物とスナップショットは無事なので、`sync.sh --apply` で
ライブ設定からオーバーレイを作り直せる。

---

## 4. なぜこの形なのか

判断の理由。変更するときはここを読んでから。

**Claude Code 側のローカル上書きは使えない。** 設定ソースは
`policy > flag > user(~/.claude/settings.json) > project(.claude/settings.json) >
local(.claude/settings.local.json ※チェックアウト単位)` の 5 つで、ユーザースコープに
local レイヤーが存在しない。CLI とデスクトップアプリで差はない。だから dotfiles 側で
マージしている。

**symlink をやめて実ファイルにした。** Claude Code はこのパスに書き戻すので、symlink の
ままだと UI 操作がそのまま追跡ファイルに入る。実ファイルなら `git clean` で dangling に
ならず、worktree から install しても壊れたリンクが残らない。

**スナップショットが要る。** 無いと「この PC がドリフトした」と「他の PC がベースを
変えた」を区別できない。区別できないと、PC-A の変更を pull した PC-B が `--apply` した
瞬間に PC-A の変更を巻き戻す（lost update）。スナップショットがあれば
`drift = live vs snapshot` / `upstream = base+overlay vs snapshot` になり 3-way マージが成立する。

**粒度はトップレベルキー。** 合成・比較・振り分けの全部で揃えてある。オーバーレイが
キーを書いたらそのキーは丸ごとオーバーレイのもの。再帰マージにすると、オーバーレイで
`enabledPlugins` の 1 エントリを消してもベースに残った同名エントリが復活してしまい、
「base+overlay がマージ結果を再現する」不変条件（書き込み前に検査している）が壊れる。

**`permissions` と `hooks` はオーバーレイに入れない。** オーバーレイはキーを丸ごと
置き換えるので、1 台だけガードレールが弱い状態を作れてしまう。`sync.sh` は
`permissions.deny` が空だったり `deny-check.sh` hook が消えていたら exit 4 で止まるが、
「deny リストが短くなっただけ」は判定できない。
