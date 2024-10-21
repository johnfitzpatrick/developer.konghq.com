# frozen_string_literal: true

module Jekyll
  class ReferencePagesGenerator < Generator
    priority :high

    def generate(site)
      ReferencePages::Generator.run(site)
    end
  end
end