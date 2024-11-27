# frozen_string_literal: true

require_relative './base'

module Jekyll
  module APIPages
    class Page < Base
      def initialize(product:, version:, file:, site:, frontmatter:)
        @product = product
        @version = version
        @file = file
        @site = site
        @frontmatter = frontmatter
      end

      def data
        @data ||= {
          'title' => api_spec.title,
          'api_spec' => api_spec,
          'description' => api_spec.description,
          'layout' => 'api/spec',
          'content_type' => 'reference',
          'canonical_url' => canonical_url,
          'seo_noindex' => true,
          'namespace' => namespace
        }.merge(@frontmatter)
      end

      private

      def namespace
        @namespace ||= @file.split('/')[1]
      end

      def url_generator
        @url_generator ||= URLGenerator::API.new(file:, version:)
      end
    end
  end
end
