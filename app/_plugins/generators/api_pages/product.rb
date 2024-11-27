# frozen_string_literal: true

require 'yaml'

module Jekyll
  module APIPages
    class Product
      attr_reader :site, :file, :product, :frontmatter

      def initialize(product:, file:, site:, frontmatter:)
        @product = product
        @file = file.gsub("#{site.source}/", '')
        @site = site
        @frontmatter = frontmatter
      end

      def generate_pages! # rubocop:disable Metrics/AbcSize
        product['versions'].map do |version|
          site.pages << Page.new(product:, version:, file:, site:, frontmatter:).to_jekyll_page
          site.pages << ErrorPage.new(product:, version:, file:, site:, errors:).to_jekyll_page if errors
        end
        site.pages << latest_page
        site.pages << latest_error_page if errors
        site.data['ssg_api_pages'] << latest_page
      end

      private

      def errors
        @errors ||= begin
          return [] unless api_spec_path

          oas = YAML.load_file(api_spec_path)
          raise ArgumentError, "Could not load #{api_spec_path}" unless oas

          oas['x-errors']
        end
      end

      def api_spec_path
        @api_spec_path ||= begin
          return nil unless @frontmatter.fetch('insomnia_link', nil)

          spec_file = CGI.unescape(@frontmatter.fetch('insomnia_link')).split('&uri=')[1].gsub(
            'https://raw.githubusercontent.com/Kong/developer.konghq.com/main/', ''
          )
          File.join(@site.source, '..', spec_file)
        end
      end

      def latest_page
        @latest_page ||= APIPages::Canonical.new(
          product:,
          version: latest_version,
          file:,
          site:,
          frontmatter:
        ).to_jekyll_page
      end

      def latest_error_page
        @latest_error_page ||= APIPages::CanonicalError.new(
          product:,
          version: latest_version,
          file:,
          site:,
          errors:
        ).to_jekyll_page
      end

      def latest_version
        @latest_version ||= @product['latestVersion']
      end
    end
  end
end
