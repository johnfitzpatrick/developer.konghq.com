# frozen_string_literal: true

require_relative '../utils/variable_replacer'
require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Presenters
        module AdminAPI
          class Base < Presenters::Base
            def url
              @url ||= Utils::VariableReplacer::URL.run(
                url: build_url,
                defaults: formats['admin-api']['variables'],
                variables: variables
              )
            end

            def data
              @data ||= @example_drop.data
            end

            def template_file
              '/components/entity_example/format/admin-api.md'
            end

            def missing_variables
              @missing_variables ||= []
            end

            private

            def build_url
              [
                formats['admin-api']['base_url'],
                formats['admin-api']['endpoints'][entity_type]
              ].join
            end
          end

          class Plugin < Base
            def data
              @example_drop.data.except(*targets.keys)
            end

            def variables
              super.merge(@example_drop.target.key => @example_drop.target.value)
            end

            def missing_variables
              return [] if @example_drop.target.key == 'global'

              @missing_variables ||= [formats['admin-api']['variables'][@example_drop.target.key]]
            end

            def build_url
              [
                formats['admin-api']['base_url'],
                formats['admin-api']['plugin_endpoints'][@example_drop.target.key]
              ].join
            end
          end
        end
      end
    end
  end
end
