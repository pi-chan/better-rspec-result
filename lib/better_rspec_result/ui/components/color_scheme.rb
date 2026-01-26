# frozen_string_literal: true

require "pastel"

module BetterRspecResult
  module UI
    module Components
      # Manages color output using Pastel
      class ColorScheme
        def initialize(enabled: true)
          @pastel = Pastel.new(enabled: enabled)
        end

        def passed(text)
          @pastel.green(text)
        end

        def failed(text)
          @pastel.red(text)
        end

        def pending(text)
          @pastel.yellow(text)
        end

        def highlight(text)
          @pastel.bright_blue(text)
        end

        def dim(text)
          @pastel.dim(text)
        end

        def success_rate(rate)
          formatted_rate = "#{rate}%"
          if rate >= 80.0
            @pastel.green(formatted_rate)
          elsif rate >= 50.0
            @pastel.yellow(formatted_rate)
          else
            @pastel.red(formatted_rate)
          end
        end
      end
    end
  end
end
