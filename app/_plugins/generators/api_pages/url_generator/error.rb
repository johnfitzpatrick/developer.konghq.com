# frozen_string_literal: true

module Jekyll
  module APIPages
    module URLGenerator
      class Error
        def initialize(file:, version:)
          @file = file
          @version = version
          @api_url = API.new(file:, version:)
        end

        def canonical_url
          @canonical_url ||= "#{@api_url.canonical_url}errors/"
        end

        def versioned_url
          @versioned_url ||= "#{@api_url.versioned_url}errors/"
        end

        def api_canonical_url
          @api_canonical_url ||= @api_url.canonical_url
        end

        def api_versioned_url
          @api_versioned_url ||= @api_url.versioned_url
        end
      end
    end
  end
end
