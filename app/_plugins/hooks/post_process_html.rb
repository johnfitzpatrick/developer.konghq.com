# frozen_string_literal: true

require 'nokogiri'

class AddLinksToHeadings # rubocop:disable Style/Documentation
  def initialize(page_or_doc)
    @page_or_doc = page_or_doc
  end

  def process # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    doc = Nokogiri::HTML(@page_or_doc.output)
    changes = false

    doc.css('h1, h2, h3, h4, h5, h6').each do |heading|
      next if heading.ancestors('.card').any?
      next if heading.ancestors('.accordion-trigger').any?
      next unless heading['id']

      anchor = Nokogiri::XML::Node.new('a', doc)
      anchor['href'] = "##{heading['id']}"
      anchor['aria-label'] = 'Anchor'
      anchor['title'] = heading.text
      anchor['class'] = 'flex items-center gap-2 link-anchor group w-full hover:no-underline text-primary'

      heading.children.each do |child|
        anchor.add_child(child)
      end

      span = Nokogiri::HTML::DocumentFragment.parse(
        <<-HTML
          <span class="text-brand hidden link-anchor-icon group-hover:flex">
            #{File.read('app/assets/icons/link.svg')}
          </span>
        HTML
      )

      anchor.add_child(span)

      changes = true
      heading.inner_html = anchor.to_s
    end

    @page_or_doc.output = doc.to_html if changes
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |page_or_doc|
  AddLinksToHeadings.new(page_or_doc).process
end
