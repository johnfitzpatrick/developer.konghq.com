# frozen_string_literal: true

require 'yaml'

module Jekyll
  class EntityExample < Liquid::Block
    def render(context) # rubocop:disable Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      unless @page['tools']
        raise ArgumentError, "Missing key `tools` in metadata on page #{@page['path']}"
      end

      example = YAML.load(contents).merge('formats' => @page['tools'])
      entity_example = EntityExamples::Base.make_for(example: example)
      entity_example_drop = entity_example.to_drop

      template = File.read(entity_example_drop.template)

      context.stack do
        context['entity_example'] = entity_example_drop
        Liquid::Template.parse(template).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
      On `#{@page['path']}`, the following {% entity_example %} block contains a malformed yaml:
      #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
      #{e.message}
      STRING
      raise ArgumentError.new(message)
    end
  end
end

Liquid::Template.register_tag('entity_example', Jekyll::EntityExample)
