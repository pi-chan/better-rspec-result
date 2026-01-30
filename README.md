# Better RSpec Result

A gem that saves RSpec test results in a structured format and provides a TUI to browse them later.

[日本語版 README](README.ja.md)

## Features

- **Structured Result Storage**: Saves RSpec execution results in JSON format
- **History Management**: Stores and browses past test results (up to 100 entries)
- **Detailed Failure Display**: Shows error messages, file paths, and line numbers
- **Color Output**: Displays pass/fail status in color
- **Simple CLI**: Browse results with the `brr` command

## Installation

### Adding to an Existing Project

#### 1. Add to Gemfile

To use from a local path:

```ruby
# Gemfile
gem 'better-rspec-result', path: '/path/to/better-rspec-result'
```

#### 2. Run bundle install

```bash
bundle install
```

That's it!

## Usage

### 1. Run RSpec to Save Test Results

#### Option A: Specify via Command Line

```bash
bundle exec rspec --format BetterRspecResult::Formatter
```

#### Option B: Add to .rspec File (Recommended)

Add the following to the `.rspec` file in your project root:

```
--format BetterRspecResult::Formatter
```

This allows results to be automatically saved when running `bundle exec rspec`:

```bash
bundle exec rspec
# => Better RSpec Result saved to: tmp/.better-rspec-results/rspec-result-YYYYMMDD-HHMMSS-NNNNNN.json
```

**Important**: With only the above setting, standard output will not be displayed. To display standard output simultaneously, specify multiple formatters:

```
--format progress
--format BetterRspecResult::Formatter
```

Or for more detailed output:

```
--format documentation
--format BetterRspecResult::Formatter
```

This allows both normal RSpec output and Better RSpec Result saving to occur simultaneously.

#### Option C: Add to RSpec Configuration File

Add to `spec/spec_helper.rb` or `spec/rails_helper.rb`:

```ruby
require 'better_rspec_result/formatter'

RSpec.configure do |config|
  config.add_formatter(BetterRspecResult::Formatter)
end
```

### 2. Browse Saved Results

#### Display Latest Result

```bash
bundle exec brr
```

Example output:

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

When there are failed tests:

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

#### Display History

```bash
bundle exec brr --list
```

Example output:

```
Found 10 result(s) in tmp/.better-rspec-results
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

#### Delete Saved Results

```bash
bundle exec brr --clean
```

#### Other Options

```bash
bundle exec brr --version  # Show version
bundle exec brr --help     # Show help
```

## Storage

Test results are saved in the `tmp/.better-rspec-results/` directory:

- File format: JSON
- File name: `rspec-result-YYYYMMDD-HHMMSS-NNNNNN.json`
- Maximum entries: 100 (oldest are automatically deleted)
- Location: `tmp/.better-rspec-results/` in project root
  - In Rails projects, `tmp/` is already included in `.gitignore`
  - Keeps your project root clean

### Customizing Storage Location

You can customize the storage location with an environment variable:

```bash
export BETTER_RSPEC_RESULTS_DIR=/path/to/custom/dir
bundle exec rspec
```

## Development

### Setup

```bash
git clone https://github.com/pi-chan/better-rspec-result.git
cd better-rspec-result
bundle install
```

### Run Tests

```bash
bundle exec rspec
```

### Install Locally

```bash
bundle exec rake install
```

## Roadmap

### Phase 1: MVP - Basic Storage and Browsing (Completed)

- [x] RSpec Custom Formatter
- [x] Result storage in JSON format
- [x] Basic CLI (`brr` command)
- [x] Latest result display
- [x] History list display
- [x] Detailed failure display

### Phase 2: Basic TUI Features (Completed)

- [x] Interactive TUI viewer
- [x] Navigation with j/k/q keys
- [x] History selection and detail display
- [x] Failed test list display
- [x] Colorful display (tty-prompt)
- [x] Direct History list display on startup
- [x] Direct Failure list display when selecting failed tests

### Phase 3: Detailed Display and Clipboard (Completed)

- [x] Error detail display (tty-box, tty-pager)
- [x] Backtrace display
- [x] Copy line number to clipboard (individual)
- [x] Bulk copy line numbers (all failed tests)

### Phase 4: Search and Filtering (Completed)

- [x] Search by file path
- [x] Search by error message
- [x] Search by description
- [x] Incremental search

### Phase 5: Optimization and Polish (Completed)

- [x] Performance optimization
- [x] Testing with large result sets
- [x] CI/CD configuration
- [x] RuboCop configuration
- [x] SimpleCov configuration

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pi-chan/better-rspec-result.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
