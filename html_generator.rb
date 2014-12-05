# encoding: utf-8

require 'pry'
require 'nokogiri'
require 'tilt/erb'

module RedBubble
  VERSION = '0.1'

  class HtmlGenerator
    attr_accessor :file_path, :output_path

    TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'output-template.html.erb'))

    def initialize(input_file_path, output_dir_path)
      self.file_path    = input_file_path
      self.output_path  = output_dir_path

      generate_image_collection!
      generate_makes!
      generate_index_html!
    end

    private

      def generate_index_html!
        generate_make_htmls!
        @unit = IndexHtmlUnit.new
        html = html_template.render(self)
        File.open(output_file(@unit), 'w') { |file| file.write(html) }
      end

      def generate_make_htmls!
        MakeHtmlUnitCollection.units.each do |unit|
          generate_model_htmls!(unit.make)
          @unit = unit
          html = html_template.render(self)
          File.open(output_file(@unit), 'w') { |file| file.write(html) }
        end
      end

      def generate_model_htmls!(make)
        ModelHtmlUnitCollection.by_make(make).each do |unit|
          @unit = unit
          html = html_template.render(self)
          File.open(output_file(@unit), 'w') { |file| file.write(html) }
        end
      end

      def generate_image_collection!
        ImageCollection.tap do |bundle|
          works.each { |work| bundle.images << Image.new(work) }
        end
      end

      def generate_makes!
        ImageCollection.all_makes.each do |make|
          generate_models_by_make!(make)
          MakeHtmlUnitCollection.units << MakeHtmlUnit.new(make)
        end
      end

      def generate_models_by_make!(make)
        ImageCollection.all_models_by_make(make).each do |model|
          ModelHtmlUnitCollection.units << ModelHtmlUnit.new(make, model)
        end
      end

      def output_file(unit)
        File.expand_path(File.join(output_path, unit.filename))
      end

      def html_template
        Tilt::ERBTemplate.new(TEMPLATE_PATH)
      end

      def works
        @works ||= document.xpath('//work')
      end

      def document 
        @xml_doc ||= Nokogiri::XML(file)
      end

      def file
        @file ||= File.open(file_path)
      end
  end


  class ModelHtmlUnit < Struct.new :make, :model
    def filename
      "model_#{make}_#{model}.html".downcase.gsub(' ', '_').gsub(/[^a-z0-9\_\.]/, '')
    end

    def title
      "#{make} | #{model}"
    end

    def navigation
      [IndexHtmlUnit.new.link, MakeHtmlUnitCollection.link_by_make(make)]
    end

    def thumbnails
      ImageCollection.by_make_model(make, model)
    end
  end


  class ModelHtmlUnitCollection
    @units = []

    class << self
      attr_accessor :units

      def links_by_make(make)
        by_make(make).uniq.map { |unit| Link.new(unit.title, unit.filename) }
      end

      def by_make(make)
        units.select { |unit| unit.make == make }
      end
    end
  end


  class MakeHtmlUnit < Struct.new :make
    def filename
      "make_#{make}.html".downcase.gsub(' ', '_').gsub(/[^a-z0-9\_\.]/, '')
    end

    def title
      make
    end

    def navigation
      [IndexHtmlUnit.new.link] + ModelHtmlUnitCollection.links_by_make(make)
    end

    def thumbnails
      ImageCollection.by_make_top(make, 10)
    end

    def models
      ModelHtmlUnitCollection.by_make(make)
    end
  end


  class MakeHtmlUnitCollection
    @units = []

    class << self
      attr_accessor :units

      def links
        units.uniq.map { |unit| Link.new(unit.title, unit.filename) }
      end

      def link_by_make(make)
        unit = units.find { |unit| unit.make == make }
        Link.new(unit.title, unit.filename)
      end
    end
  end


  class IndexHtmlUnit
    def filename
      "index.html"
    end

    def title
      "Index"
    end

    def navigation
      MakeHtmlUnitCollection.links
    end

    def thumbnails
      ImageCollection.get_any_top(10)
    end

    def link
      Link.new(title, filename)
    end
  end


  class Link < Struct.new :title, :filename
  end


  class Image < Struct.new :work
    def filename
      @filename ||= work.css('filename').text
    end

    def image_width
      @image_width ||= work.css('image_width').text
    end

    def image_height
      @image_height ||= work.css('image_height').text
    end

    def make
      text = exif.css('make').text
      @make ||= text.empty? ? 'Unnknown Make' : text
    end

    def model
      text = exif.css('model').text
      @model ||= text.empty? ? 'Unnknown Model' : text
    end

    def url
      @url ||= URL.new(work.css('urls'))
    end

    private

      def exif
        @exif ||= work.css('exif')
      end
  end


  class URL < Struct.new :types
    def small
      @small ||= types.css('url[@type="small"]').first.text
    end

    def medium
      @medium ||= types.css('url[@type="medium"]').first.text
    end

    def large
      @large ||= types.css('url[@type="large"]').first.text
    end
  end


  class ImageCollection
    @images = []

    class << self
      attr_accessor :images

      def get_any_top(number)
        images.take(number)
      end

      def by_make(make)
        images.select { |image| image.make == make }
      end

      def by_make_top(make, number)
        by_make(make).take(number)
      end

      def by_make_model(make, model)
        by_make(make).select { |image| image.model == model }
      end

      def all_makes
        images.map(&:make)
      end

      def all_models_by_make(make)
        by_make(make).map(&:model)
      end
    end
  end
end


if __FILE__ == $0
  RedBubble::HtmlGenerator.new(File.absolute_path(ARGV[0]), File.absolute_path(ARGV[1]))
end
