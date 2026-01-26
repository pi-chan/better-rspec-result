# frozen_string_literal: true

require "tty-prompt"

module BetterRspecResult
  module UI
    # Provides custom key bindings for TTY::Prompt
    module KeyBindings
      # Custom List class with vim-style j/k navigation
      class VimList < TTY::Prompt::List
        def keypress(event)
          # Handle vim-style navigation
          case event.value
          when "j"
            keydown
          when "k"
            keyup
          else
            super
          end
        end
      end

      def self.create_prompt
        prompt = TTY::Prompt.new

        # Override select method to use VimList
        def prompt.select(question, *args, &block)
          invoke_select(BetterRspecResult::UI::KeyBindings::VimList, question, *args, &block)
        end

        prompt
      end
    end
  end
end
