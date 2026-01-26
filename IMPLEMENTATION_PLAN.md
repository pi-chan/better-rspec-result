# Better RSpec Result - 実装計画

## Phase 1: MVP - 基本的な保存と閲覧 ✅ 完了

**目標**: RSpec結果を保存し、最新結果を閲覧できる最小機能

**実装内容**:
- [x] Gem scaffold生成
- [x] gemspecに依存関係追加
- [x] Storage Layer実装
  - [x] `Result` データモデル（サマリー、失敗例へのアクセサ）
  - [x] `JsonStorage`（save/load/list_results）
- [x] RSpec Formatter実装
  - [x] RSpec::Core::Formatters::BaseFormatterを継承
  - [x] 各イベント（start/example_*/dump_summary/close）をフック
  - [x] JSON形式で保存
- [x] 基本的なCLI（`exe/brr`）
  - [x] 最新結果の表示（プレーンテキスト）
  - [x] `--help`, `--version`, `--clean`, `--list` オプション
- [x] テストカバレッジ80%以上（77 examples, 100%パス）

---

## Phase 2: TUI基本機能 (1-2週間)

**目標**: インタラクティブなTUIで履歴と失敗を閲覧

### 実装するクラス

```
lib/better_rspec_result/ui/
├── viewer.rb         # メインTUIビューア（エントリポイント）
├── history_list.rb   # 履歴一覧画面
└── failure_list.rb   # 失敗テスト一覧画面
```

### 実装タスク

1. **Viewer クラス実装**
   - メインメニューの表示
   - tty-promptの`select`メソッドを使用
   - メニュー項目:
     - `View Latest Result` → 最新結果のサマリー表示 → 失敗があれば `View failures?`
     - `View History` → 履歴一覧へ
     - `Search Results` → 検索機能へ（Phase 4で実装）
     - `Exit`

2. **HistoryList クラス実装**
   - 履歴一覧をインタラクティブに表示
   - tty-promptの`select`を使用
   - 各項目の表示形式:
     ```
     [PASSED] 2026-01-26 15:30 | 50 examples, 0 failures | 2.5s
     [FAILED] 2026-01-26 14:00 | 50 examples, 5 failures | 3.1s
     ```
   - 選択後、選択した結果の詳細メニューへ:
     - `View Summary` → サマリー表示
     - `View Failed Examples` → 失敗一覧へ
     - `View All Examples` → 全テスト一覧（pager使用）
     - `← Back` → 履歴一覧に戻る

3. **FailureList クラス実装**
   - 失敗したテストの一覧をインタラクティブに表示
   - tty-promptの`select`を使用
   - 各項目の表示形式:
     ```
     [1] User validations returns true for valid user
         spec/models/user_spec.rb:15
     ```
   - 選択後、詳細表示（Phase 3で実装）
   - 最下部に追加オプション:
     - `Copy All Line Numbers` → 全失敗テストの行番号コピー（Phase 3）
     - `← Back` → 前の画面に戻る

4. **カラー出力の強化**
   - pastelを使用した色分け
   - ステータス:
     - `PASSED` → 緑
     - `FAILED` → 赤
     - `PENDING` → 黄色
   - 失敗カウント → 赤で強調
   - 成功率 → 80%以上は緑、それ以下は黄色または赤

5. **キーバインディング**
   - `↑/↓` または `j/k` → 移動（tty-promptのデフォルト）
   - `Enter` → 選択
   - `q` または `Ctrl+C` → 終了/戻る

### テスト戦略

- 各UIクラスのユニットテスト
  - モックを使用してtty-promptの動作をテスト
  - 表示内容の検証
- 手動テスト
  - 実際のTUIナビゲーション
  - キーボード操作の確認

### 成功基準

- ✅ メインメニューが表示される
- ✅ 履歴一覧がインタラクティブに表示される
- ✅ 履歴から結果を選択して詳細表示できる
- ✅ 失敗テスト一覧が表示される
- ✅ カラー出力が正しく動作する

---

## Phase 3: 詳細表示とクリップボード (1週間)

**目標**: エラー詳細表示と行番号コピー

### 実装するクラス

```
lib/better_rspec_result/ui/
├── detail_view.rb    # エラー詳細表示
└── clipboard.rb      # クリップボード操作（外部）
```

### 実装タスク

1. **DetailView クラス実装**
   - 選択した失敗テストの詳細表示
   - tty-boxでエラー情報をボックス表示:
     ```
     ┌─ User validations returns true for valid user ─────────────────┐
     │ Location: spec/models/user_spec.rb:15                          │
     │                                                                 │
     │ Error Class: RSpec::Expectations::ExpectationNotMetError       │
     │                                                                 │
     │ Message:                                                        │
     │   expected true, got false                                      │
     │                                                                 │
     │ Backtrace:                                                      │
     │   spec/models/user_spec.rb:21:in `block (3 levels)'            │
     │   /path/to/rspec-core/lib/rspec/core/example.rb:123            │
     │   ...                                                           │
     └─────────────────────────────────────────────────────────────────┘
     ```
   - バックトレースが長い場合はtty-pagerを使用
   - プロジェクトディレクトリのファイルをハイライト
   - 詳細表示後のオプション:
     - `Copy Line Number` → `file_path:line_number` をコピー
     - `Copy Full Location` → フルパスをコピー
     - `View Full Backtrace` → 完全なバックトレースをpagerで表示
     - `← Back` → 失敗一覧に戻る

2. **Clipboard クラス実装**
   - clipboard gemを使用
   - クロスプラットフォーム対応:
     - macOS: pbcopy（自動対応）
     - Linux: xclip/xsel（自動対応）
     - Windows: clip.exe（自動対応）
   - コピー機能:
     - 個別行番号コピー: `spec/models/user_spec.rb:15`
     - 一括行番号コピー: 全失敗テストの行番号を改行区切りで
   - フォールバック処理:
     - クリップボードが使えない場合はファイルに保存
     - `~/.better-rspec-results/failed_locations.txt` に書き出し
     - ユーザーに通知

3. **CLI統合**
   - `--copy-failures` オプション追加
   - 最新結果の失敗テストを自動コピー
   - 例: `brr --copy-failures` → 全失敗テストの行番号をコピー

### テスト戦略

- DetailViewのレンダリングテスト
- Clipboardのモックテスト
- 各OSでのクリップボード動作確認（手動）

### 成功基準

- ✅ エラー詳細が見やすく表示される
- ✅ 長いバックトレースがpagerで表示される
- ✅ 行番号がクリップボードにコピーされる
- ✅ 一括コピーが動作する
- ✅ フォールバック処理が動作する

---

## Phase 4: 検索・フィルタリング (1週間)

**目標**: 過去の結果から検索

### 実装するクラス

```
lib/better_rspec_result/ui/
└── search.rb         # 検索・フィルタリング
```

### 実装タスク

1. **Search クラス実装**
   - メインメニューから `Search Results` を選択
   - 検索方法の選択:
     - `Search by file path` → ファイルパスで検索
     - `Search by error message` → エラーメッセージで検索
     - `Search by description` → テスト説明で検索
     - `← Back` → メインメニューに戻る
   - 検索実行:
     - tty-promptの`ask`で検索キーワード入力
     - 部分一致で検索
     - 大文字小文字を区別しない
   - 検索結果表示:
     - マッチした結果をリスト表示
     - 選択して詳細表示へ
     - マッチ箇所をハイライト

2. **フィルタリング強化**
   - 履歴一覧でのフィルタリング
   - tty-promptの`filter: true`オプション活用
   - インクリメンタルサーチ
   - フィルタ条件:
     - ステータス（PASSED/FAILED/ALL）
     - 日付範囲
     - 失敗数の範囲

3. **検索結果のハイライト**
   - pastelを使用してマッチ箇所を強調
   - 例:
     ```
     spec/models/user_spec.rb:15
              ^^^^          (検索キーワード: "user" でマッチ)
     ```

### テスト戦略

- 検索ロジックのユニットテスト
- 各検索方法のテスト
- フィルタリングのテスト

### 成功基準

- ✅ ファイルパスで検索できる
- ✅ エラーメッセージで検索できる
- ✅ 説明文で検索できる
- ✅ 検索結果がハイライト表示される
- ✅ フィルタリングが動作する

---

## Phase 5: 最適化と仕上げ (1週間)

**目標**: パフォーマンス最適化とドキュメント整備

### 実装タスク

1. **パフォーマンス最適化**
   - 大量結果での動作確認（100件以上）
   - JSONパースの遅延読み込み:
     - 履歴一覧ではサマリーのみ読み込み
     - 詳細表示時に完全なデータを読み込み
   - メタデータファイルの導入:
     - `~/.better-rspec-results/index.json` にサマリー情報を保存
     - 起動速度の向上
   - メモリ使用量の最適化

2. **設定機能の追加**
   - 設定ファイル: `~/.better-rspec-results/config.json`
   - 設定項目:
     - `max_results`: 最大保存件数（デフォルト: 100）
     - `storage_dir`: 保存先ディレクトリ
     - `default_view`: デフォルト表示（latest/history/menu）
     - `color_scheme`: カラースキーム（light/dark）
   - CLI オプション:
     - `brr --config` → 設定ファイルを開く
     - `brr --set key=value` → 設定を変更

3. **ドキュメント整備**
   - README.md更新
     - スクリーンショット追加（asciicast）
     - 詳細な使用例
     - トラブルシューティング
   - CHANGELOG.md作成
     - 各バージョンの変更履歴
   - コード内ドキュメント
     - YARD形式のドキュメント
     - 各クラスとメソッドの説明

4. **CI/CD設定**
   - GitHub Actions設定（.github/workflows/）
     - `test.yml`: 複数OS/Rubyバージョンでテスト
       - macOS, Ubuntu, Windows
       - Ruby 3.0, 3.1, 3.2, 3.3
     - `lint.yml`: RuboCop実行
     - `coverage.yml`: SimpleCov実行
   - RuboCop設定（.rubocop.yml）
     - Ruby Style Guideに準拠
     - プロジェクト固有のルール
   - SimpleCov設定
     - カバレッジ80%以上を維持
     - HTMLレポート生成

5. **エラーハンドリング強化**
   - ファイル読み込みエラー
   - JSON parse エラー
   - クリップボードエラー
   - 権限エラー
   - わかりやすいエラーメッセージ

### テスト戦略

- パフォーマンステスト
  - 100件の結果で起動時間を測定
  - メモリ使用量を測定
- エッジケーステスト
  - 空の結果
  - 破損したJSONファイル
  - 権限のないディレクトリ

### 成功基準

- ✅ 100件の結果でも快適に動作する
- ✅ 起動時間が1秒以内
- ✅ メモリ使用量が適切
- ✅ すべてのドキュメントが整備されている
- ✅ CI/CDが設定されている
- ✅ テストカバレッジ80%以上
- ✅ RubocopでWarningなし

---

## Phase 6: 将来的な拡張（オプション）

### 統計レポート機能

- 成功率の推移グラフ（ASCII art）
- よく失敗するテストのランキング
- テスト実行時間の推移
- 日別/週別/月別の統計

### エクスポート機能

- HTML形式でのレポート出力
- PDF形式でのレポート出力
- Markdown形式でのレポート出力
- GitHub Issueへの自動投稿

### Gitインテグレーション

- コミットハッシュとの紐付け
- ブランチ情報の記録
- PRとの連携

### 通知機能

- デスクトップ通知（失敗時）
- Slack通知
- メール通知

### CI/CD統合

- GitHub Actions連携
- CircleCI連携
- GitLab CI連携
- JUnit形式のレポート出力

### プラグインシステム

- カスタムフォーマッター
- カスタムビューア
- カスタム通知

---

## データ構造（JSON Schema）

現在のデータ構造：

```json
{
  "metadata": {
    "version": "0.1.0",
    "timestamp": "2026-01-26T14:30:15+09:00",
    "command": "bundle exec rspec spec/models/",
    "seed": 12345,
    "rspec_version": "3.13.0",
    "ruby_version": "3.3.0",
    "working_directory": "/path/to/project"
  },
  "summary": {
    "duration": 2.5,
    "example_count": 50,
    "failure_count": 5,
    "pending_count": 0,
    "errors_outside_of_examples_count": 0
  },
  "examples": [
    {
      "id": "./spec/models/user_spec.rb[1:1:1]",
      "description": "valid? returns true for valid user",
      "full_description": "User validations valid? returns true for valid user",
      "status": "failed",
      "file_path": "spec/models/user_spec.rb",
      "line_number": 15,
      "run_time": 0.05,
      "exception": {
        "class": "RSpec::Expectations::ExpectationNotMetError",
        "message": "expected true, got false",
        "backtrace": [...]
      }
    }
  ]
}
```

### Phase 5以降の拡張予定

```json
{
  "metadata": {
    // 既存のフィールド
    "git_commit": "abc123...",  // Gitコミットハッシュ
    "git_branch": "feature/new", // Gitブランチ名
    "ci_build_id": "12345",      // CIビルドID
    "environment": "test"         // 実行環境
  }
}
```

---

## UI画面遷移（完全版）

```
[メインメニュー]
├─ View Latest Result → [サマリー表示] ─┐
│                                       │
│  ┌────────────────────────────────────┘
│  │
│  └─ View failures? → [失敗一覧] → [詳細表示] → Copy Line Number
│                           │               │
│                           └─ Copy All ────┘
│
├─ View History → [履歴一覧] (j/k, filter) → [結果詳細メニュー]
│                                               ├─ View Summary
│                                               ├─ View Failed Examples → [失敗一覧]
│                                               ├─ View All Examples (pager)
│                                               └─ ← Back
│
├─ Search Results → [検索方法選択]
│                     ├─ Search by file path ──┐
│                     ├─ Search by error msg ──┤
│                     └─ Search by description ┘
│                              ↓
│                     [検索キーワード入力]
│                              ↓
│                     [検索結果一覧] → [詳細表示]
│
└─ Exit
```

---

## キーバインディング（完全版）

- `j/k` または `↑/↓`: 移動
- `Enter`: 選択
- `q` または `ESC` または `Ctrl+C`: 戻る/終了
- `c`: コピー（詳細表示時）
- `a`: 一括コピー（失敗一覧時）
- `/`: 検索/フィルター開始
- `h`: ヘルプ表示
- `r`: 更新（履歴一覧時）

---

## 開発の進め方

1. 各フェーズを順番に実装
2. 各フェーズ終了時に動作確認
3. テストを書きながら実装（TDD）
4. コードレビュー（自己レビュー + code-reviewer エージェント）
5. ドキュメント更新
6. コミット作成

## 推奨ツール

- **TDD**: tdd-guide エージェント
- **コードレビュー**: code-reviewer エージェント
- **セキュリティ**: security-reviewer エージェント
- **リファクタリング**: refactor-cleaner エージェント
- **ドキュメント**: doc-updater エージェント
