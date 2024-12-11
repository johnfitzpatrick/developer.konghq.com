# frozen_string_literal: true

module Jekyll
  module PluginPages
    class Generator
      PLUGINS_FOLDER = '_kong_plugins'

      def self.run(site)
        new(site).run
      end

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def run
        Dir.glob(File.join(site.source, "#{PLUGINS_FOLDER}/*/")).each do |folder|
          slug = folder.gsub("#{site.source}/#{PLUGINS_FOLDER}/", '').chomp('/')

          generate_pages(Jekyll::PluginPages::Plugin.new(folder:, slug:))
        end
      end

      def generate_pages(plugin)
        generate_overview_page(plugin)
        generate_reference_page(plugin)
        generate_changelog_page(plugin)
        generate_example_pages(plugin)
      end

      def generate_overview_page(plugin)
        overview = Jekyll::PluginPages::Pages::Overview
                   .new(plugin:, file: File.join(plugin.folder, 'index.md'))
                   .to_jekyll_page

        site.data['kong_plugins'][plugin.slug] = overview
        site.pages << overview
      end

      def generate_reference_page(plugin)
        reference = Jekyll::PluginPages::Pages::Reference
                    .new(plugin:, file: File.join(plugin.folder, 'reference.md'))
                    .to_jekyll_page

        site.pages << reference
      end

      def generate_changelog_page(plugin)
        changelog = Jekyll::PluginPages::Pages::Changelog
                    .new(plugin:, file: File.join(plugin.folder, 'changelog.md'))
                    .to_jekyll_page

        site.pages << changelog
      end

      def generate_example_pages(plugin)
        plugin.example_files.each do |example_file|
          example = Jekyll::PluginPages::Pages::Example
                    .new(plugin:, file: example_file)
                    .to_jekyll_page

          site.pages << example
        end
      end
    end
  end
end
