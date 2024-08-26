# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class KIC < Base
          def template_file
            @template_file ||= "/components/entity_example/format/kic.md"
          end

          def to_option
            'KIC'
          end
        end
      end
    end
  end
end
