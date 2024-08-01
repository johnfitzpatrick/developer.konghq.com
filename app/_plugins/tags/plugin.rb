# frozen_string_literal: true

module Jekyll
  class RenderPlugin < Liquid::Tag
    def initialize(tag_name, param, tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site    = context.registers[:site]
      @page    = @context.environments.first['page']
      @config = @param.split('.').reduce(context) { |c, key| c[key] } || @param
      @plugin_slug = @config.is_a?(Hash) ? @config['slug'] : @config

      plugin = @site.collections['kong_plugins'].docs.find do |d|
        d.data['slug'] == @plugin_slug
      end

      raise ArgumentError, "Error rendering {% plugin %} on page: #{@page['path']}. The plugin `#{@plugin_slug}` doesn't exist." unless plugin

      @context.environments.unshift('plugin' => plugin)

      rendered_content = Liquid::Template.parse(template).render(@context)

      @context.environments.shift

      rendered_content
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/plugin.html'))
    end
  end
end

Liquid::Template.register_tag('plugin', Jekyll::RenderPlugin)
