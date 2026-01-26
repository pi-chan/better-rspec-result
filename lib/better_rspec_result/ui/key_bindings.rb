# frozen_string_literal: true

require "tty-prompt"

module BetterRspecResult
  module UI
    # Provides custom key bindings for TTY::Prompt
    module KeyBindings
      # Custom List class with vim-style j/k navigation and q for quit
      class VimList < TTY::Prompt::List
        def keypress(event)
          # Handle vim-style navigation and quit
          case event.value
          when "j"
            keydown
          when "k"
            keyup
          when "q"
            # Find and select the :back option if it exists
            back_index = choices.find_index { |c| c.value == :back }
            if back_index
              @active = back_index
              trigger(:keyreturn)
            end
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
