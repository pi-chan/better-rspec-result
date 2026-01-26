# frozen_string_literal: true

require "tty-prompt"

module BetterRspecResult
  module UI
    # Provides custom key bindings for TTY::Prompt
    module KeyBindings
      # Custom List class with vim-style j/k navigation and q for quit
      class VimList < TTY::Prompt::List
        def initialize(*args, **kwargs)
          super(*args, **kwargs)
          @q_pressed = false
        end

        def keypress(event)
          # Handle vim-style navigation and quit
          case event.value
          when "j"
            keydown
          when "k"
            keyup
          when "q"
            # Mark that q was pressed and return
            @q_pressed = true
            @done = true
          else
            super
          end
        end

        def answer
          # If q was pressed, return :back
          if @q_pressed
            back_choice = choices.find { |c| c.value == :back }
            return back_choice if back_choice
          end
          # Otherwise, use default behavior
          super
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
