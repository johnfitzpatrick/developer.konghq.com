# frozen_string_literal: true

require 'yaml'

module Jekyll
  module Drops
    class PluginConfigExample < Liquid::Drop # rubocop:disable Style/Documentation
      class EnvVariable < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(variable) # rubocop:disable Lint/MissingSuper
          @variable = variable
        end

        def value
          @value ||= @variable.fetch('value').gsub(/^\$/, '')
        end

        def description
          @description ||= @variable['description']
        end
      end

      attr_reader :file

      def initialize(file:, plugin:) # rubocop:disable Lint/MissingSuper
        @file   = file
        @plugin = plugin
      end

      def slug
        @slug ||= File.basename(@file, File.extname(@file))
      end

      def config
        @config ||= example.fetch('config', {})
      end

      def description
        @description ||= example.fetch('description')
      end

      def requirements
        @requirements ||= example.fetch('requirements', [])
      end

      def variables
        @variables ||= example.fetch('variables', {}).map do |k, v|
          EnvVariable.new(v)
        end
      end

      def plugin_slug
        @plugin_slug ||= @plugin.slug
      end

      def title
        @title ||= example.fetch('title')
      end

      def weight
        @weight ||= example.fetch('weight')
      end

      def entity_examples # rubocop:disable Metrics/MethodLength
        @entity_examples ||= @plugin.targets.map do |target|
          EntityExampleBlock::Plugin.new(
            example: {
              'type' => 'plugin',
              'data' => {
                'name' => plugin_slug,
                target => nil,
                'config' => config
              },
              'formats' => formats,
              'variables' => example.fetch('variables', {})
            }
          ).to_drop
        end
      end

      def targets
        @targets ||= @plugin.targets
      end

      def formats
        @formats ||= example.fetch('tools')
      end

      def url
        @url ||= "/plugins/#{@plugin.slug}/examples/#{slug}/"
      end

      def id
        @id ||= SecureRandom.hex(10)
      end

      private

      def example
        @example ||= YAML.load(File.read(@file))
      end

      def site
        @site ||= Jekyll.sites.first
      end
    end
  end
end
