module Jekyll
  class GifTag < Liquid::Tag
    def initialize(tag_name, gif_name, tokens)
      super
      @gif_name = gif_name.strip
    end

    def render(context)
      "<img src='/assets/gifs/#{@gif_name}' alt='#{@gif_name} gif'>"
    end
  end
end

Liquid::Template.register_tag('gif', Jekyll::GifTag)

