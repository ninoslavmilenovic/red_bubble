# encoding: utf-8
# html_generator.rb

require 'cobravsmongoose'
require 'tilt/erb'


module RedBubble
  VERSION = '0.1'

  class HtmlGenerator
    #
    # HtmlGenerator is a batch processor which uses EXIF data
    # exported from a selection of images and generates a set of static HTML files
    # to allow a user to browse these images.
    #
    # This script should be run from the command line and it should take two arguments:
    #   - Path to the input *.xml file containing EXIF data structured like the works.xml file
    #     provided with this script.
    #   - Path to the output directory where static HTML files will be saved.
    # These paths can be both relative and absolute.
    #
    # Example:
    #   $ ruby html_generator.rb <input_file_path> <output_directory_path>
    # 
    #   $ ruby html_generator.rb works.xml static_html/
    #
    # How does it work:
    # 
    # On HtmlGenerator instance initialization, 
    # *.xml file is parsed and converted to Hash since it's a native Ruby data type
    # so it will allow for the input file type to be easily changed from *.xml
    # to anything else by simply swapping the mapper. 
    #
    # By looping through this Hash
    # Image objects are generated for each `work` and appended to the ImageCollection.
    # 
    # In the next step, three types of HtmlUnit objects are used 
    # to generate distinct types of static html data objects [Index, Makes, Models],
    # which are then appended to their respective collections.
    #
    # Last step is taking all these pre-generated object collections
    # and rendering a distinct static html pages using the one provided html template file.
    #
    # Each page has it's respective title, navigation and thumbnail images 
    # which are linked with their respective full time images.
    #
    attr_accessor :file_path, :output_path

    #
    # Remember to update the constant in case the 'output-template.html.erb' template 
    # is not located in the same directory as this script.
    #
    TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'output-template.html.erb'))

    def initialize(input_file_path, output_dir_path)
      self.file_path    = input_file_path
      self.output_path  = output_dir_path

      generate_image_collection!
    end

    private

      def generate_image_collection!
        ImageCollection.tap do |bundle|
          works.each { |work| bundle.images << Image.new(work) }
        end
        generate_makes!
      end

      def generate_index_html!
        generate_make_htmls!
        save_html_file(self, IndexHtmlUnit.new)
      end

      def generate_make_htmls!
        MakeHtmlUnitCollection.units.each do |unit|
          generate_model_htmls!(unit.make)
          save_html_file(self, unit)
        end
      end

      def generate_model_htmls!(make)
        ModelHtmlUnitCollection.by_make(make).each do |unit|
          save_html_file(self, unit)
        end
      end

      def generate_makes!
        ImageCollection.all_makes.each do |make|
          generate_models_by_make!(make)
          MakeHtmlUnitCollection.units << MakeHtmlUnit.new(make)
        end
        generate_index_html!
      end

      def generate_models_by_make!(make)
        ImageCollection.all_models_by_make(make).each do |model|
          ModelHtmlUnitCollection.units << ModelHtmlUnit.new(make, model)
        end
      end

      def save_html_file(context, unit)
        @unit = unit
        File.open(output_file(unit), 'w') do |file| 
          file.write(html_template.render(context))
        end
      end

      def output_file(unit)
        File.expand_path(File.join(output_path, unit.filename))
      end

      def html_template
        Tilt::ERBTemplate.new(TEMPLATE_PATH)
      end

      def works
        @works ||= hash['works']['work']
      end

      def hash 
        @hash ||= CobraVsMongoose.xml_to_hash(file_content)
      end

      def file_content
        @file_content ||= File.read(file_path)
      end
  end


  module HtmlUnit 
    def generate_filename(base)
      "#{base}.html".downcase.gsub(' ', '_').gsub(/[^a-z0-9\_\.]/, '')
    end 
  end


  class ModelHtmlUnit < Struct.new :make, :model
    include HtmlUnit

    def filename
      generate_filename("model_#{make}_#{model}")
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
    include HtmlUnit

    def filename
      generate_filename("make_#{make}")
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
      'index.html'
    end

    def title
      'Index'
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


  class URL
    #
    # URL object exists as a container of URLs of different sizes.
    # It accepts a Hash with the following structure:
    #
    #   { "url" => [
    #       {"@type" => "small",  "$" => "http://<...>s.jpg" },
    #       {"@type" => "medium", "$" => "http://<...>m.jpg" },
    #       {"@type" => "large",  "$" => "http://<...>l.jpg" }
    #     ]
    #   }
    #
    # Example:
    #
    #   > url = URL.new({"url" => [...]})
    #   > url.small
    #   => "http://<...>s.jpg"
    #
    attr_accessor :types

    def initialize(types)
      raise(ArgumentError, 'Invalid Type. Hash expected.') unless types.kind_of?(Hash)
      raise(StandardError, 'Hash is mising `url` key.') unless types.key?('url')
      raise(StandardError, '`url` key should containt an array.') unless types['url'].kind_of?(Array)

      self.types = types
    end

    def small
      url = types['url'].find { |url| url['@type'] == 'small' }
      raise(StandardError, 'URL details are missing.') if url.nil?
      @small ||= url['$']
    end

    def medium
      url = types['url'].find { |url| url['@type'] == 'medium' }
      raise(StandardError, 'URL details are missing.') if url.nil?
      @medium ||= url['$']
    end

    def large
      url = types['url'].find { |url| url['@type'] == 'large' }
      raise(StandardError, 'URL details are missing.') if url.nil?
      @large ||= url['$']
    end
  end


  class Image < Struct.new :work
    def filename
      @filename ||=  work['filename']['$']
    end

    def image_width
      @image_width ||= work['image_width']['$']
    end

    def image_height
      @image_height ||= work['image_height']['$']
    end

    def make
      if exif['make']
        text = exif['make']['$']
      @make ||= text.empty? ? 'Unknown Make' : text
      else
        'Unknown Make'
      end
    end

    def model
      if exif['model']
      text = exif['model']['$']
      @model ||= text.empty? ? 'Unknown Model' : text
    else
      'Missing Model'
    end
    end

    def url
      @url ||= URL.new(work['urls'])
    end

    private

      def exif
        @exif ||= work['exif']
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
