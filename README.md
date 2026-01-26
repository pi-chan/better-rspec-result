# Better RSpec Result

RSpecのテスト結果を構造化して保存し、TUIで後から閲覧できるgemです。

## Features

- **構造化された結果保存**: RSpecの実行結果をJSON形式で保存
- **履歴管理**: 過去のテスト結果を保存・閲覧（最大100件）
- **失敗テストの詳細表示**: エラーメッセージ、ファイルパス、行番号を表示
- **カラー出力**: 成功/失敗をカラーで表示
- **簡単なCLI**: `brr` コマンドで結果を閲覧

## Installation

### 既存プロジェクトに導入

#### 1. Gemfileに追加

ローカルパスから使用する場合：

```ruby
# Gemfile
gem 'better-rspec-result', path: '/Users/hiromasa/.ghq/gh/pi-chan/better-rspec-result'
```

#### 2. bundle install

```bash
bundle install
```

これで導入完了です！

## Usage

### 1. RSpecを実行してテスト結果を保存

#### 方法A: コマンドラインオプションで指定

```bash
bundle exec rspec --format BetterRspecResult::Formatter
```

#### 方法B: .rspecファイルに追加（推奨）

プロジェクトルートの `.rspec` ファイルに以下を追加：

```
--format BetterRspecResult::Formatter
```

これにより、通常通り `bundle exec rspec` を実行するだけで結果が自動保存されます：

```bash
bundle exec rspec
# => Better RSpec Result saved to: ~/.better-rspec-results/rspec-result-YYYYMMDD-HHMMSS-NNNNNN.json
```

**重要**: 上記の設定だけでは標準出力が表示されなくなります。標準出力も同時に表示したい場合は、複数のformatterを指定してください：

```
--format progress
--format BetterRspecResult::Formatter
```

または、より詳細な出力が必要な場合：

```
--format documentation
--format BetterRspecResult::Formatter
```

これにより、通常のRSpec出力とBetter RSpec Resultの保存が同時に行われます。

#### 方法C: RSpec設定ファイルに追加

`spec/spec_helper.rb` または `spec/rails_helper.rb` に追加：

```ruby
require 'better_rspec_result/formatter'

RSpec.configure do |config|
  config.add_formatter(BetterRspecResult::Formatter)
end
```

### 2. 保存された結果を閲覧

#### 最新の結果を表示

```bash
bundle exec brr
```

出力例：

```
================================================================================
Better RSpec Result
================================================================================

Timestamp: 2026-01-26T15:13:37+09:00
Duration: 2.5s
Working Directory: /path/to/project
Ruby Version: 3.3.4
RSpec Version: 3.13.6

Status: PASSED
Examples: 50
Failures: 0
Pending: 0
Success Rate: 100.0%

================================================================================
```

失敗したテストがある場合：

```
================================================================================
Failed Examples:
================================================================================

1. User validations returns true for valid user
   Location: spec/models/user_spec.rb:15
   Error: RSpec::Expectations::ExpectationNotMetError: expected true, got false

2. Authentication login with invalid credentials
   Location: spec/services/auth_spec.rb:42
   Error: RSpec::Expectations::ExpectationNotMetError: ...
```

#### 履歴を表示

```bash
bundle exec brr --list
```

出力例：

```
Found 10 result(s) in ~/.better-rspec-results
Total size: 125.5 KB

1. FAILED - 2026-01-26T15:30:00+09:00
   50 examples, 5 failures, 0 pending
   Duration: 2.5s
   File: rspec-result-20260126-153000-123456.json

2. PASSED - 2026-01-26T15:00:00+09:00
   50 examples, 0 failures, 0 pending
   Duration: 2.3s
   File: rspec-result-20260126-150000-654321.json
```

#### 保存された結果を削除

```bash
bundle exec brr --clean
```

#### その他のオプション

```bash
bundle exec brr --version  # バージョン表示
bundle exec brr --help     # ヘルプ表示
```

## Storage

テスト結果は `~/.better-rspec-results/` ディレクトリに保存されます：

- ファイル形式: JSON
- ファイル名: `rspec-result-YYYYMMDD-HHMMSS-NNNNNN.json`
- 最大保存件数: 100件（古いものから自動削除）

## Development

### Setup

```bash
git clone https://github.com/pi-chan/better-rspec-result.git
cd better-rspec-result
bundle install
```

### Run tests

```bash
bundle exec rspec
```

### Install locally

```bash
bundle exec rake install
```

## Roadmap

### Phase 1: MVP - 基本的な保存と閲覧 ✅ 完了

- [x] RSpec Custom Formatter
- [x] JSON形式での結果保存
- [x] 基本的なCLI（`brr` コマンド）
- [x] 最新結果の表示
- [x] 履歴一覧表示
- [x] 失敗テストの詳細表示

### Phase 2: TUI基本機能（予定）

- [ ] インタラクティブなTUIビューア
- [ ] j/k キーでのナビゲーション
- [ ] 履歴選択と詳細表示
- [ ] 失敗テスト一覧の表示
- [ ] カラフルな表示（tty-prompt）

### Phase 3: 詳細表示とクリップボード ✅ 完了

- [x] エラー詳細表示（tty-box, tty-pager）
- [x] バックトレース表示
- [x] 行番号のクリップボードコピー（個別）
- [x] 一括行番号コピー（全失敗テスト）

### Phase 4: 検索・フィルタリング（予定）

- [ ] ファイルパスでの検索
- [ ] エラーメッセージでの検索
- [ ] 説明文での検索
- [ ] インクリメンタルサーチ

### Phase 5: 最適化と仕上げ（予定）

- [ ] パフォーマンス最適化
- [ ] 大量結果での動作確認
- [ ] CI/CD設定
- [ ] RuboCop設定
- [ ] SimpleCov設定

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pi-chan/better-rspec-result.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
