# encoding: utf-8
# html_generator.rb

# RedBubble::HtmlGenerator: Batch processor
#
#  Usage:  ruby html_generator.rb  [input_file_path, output_destination_path]
#

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

      #
      # @unit instance variable is re-assigned 
      # each time the method is being invoked.
      #
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

      #
      # Xml is being converted/mapped to Hash for the purpose of having the flexibility
      # of enabling multiple input file types by simply swapping the mapping engine on the later stage
      # without having to update other parts of the code, as Hash is the native data structure.
      #
      def hash 
        @hash ||= CobraVsMongoose.xml_to_hash(file_content)
      end

      def file_content
        @file_content ||= File.read(file_path)
      end
  end


  #
  # Factored-out module for sharing the method with all HtmlUnit* objects.
  #
  module HtmlUnit 
    #
    # Shaping the unit name into the format applicable for filenames.
    #
    def generate_filename(base)
      "#{base}.html".downcase.gsub(' ', '_').gsub(/[^a-z0-9\_\.]/, '')
    end 
  end


  #
  # Contains data needed for rendering the html page 
  # with all images captured by a specific camera make 
  # and a specific camera model in the give make range.
  #
  # It takes two arguments of type String:
  #   Example:
  #
  #   > model = ModelHtmlUnit.new('Nikon', 'D7100')
  #   > model.filename
  #   => "model_nikon_d7100.html"
  # 
  #   > model.title
  #   => "Nikon | D7100"
  #
  class ModelHtmlUnit < Struct.new :make, :model
    include HtmlUnit

    def filename
      generate_filename("model_#{make}_#{model}")
    end

    def title
      "#{make} | #{model}"
    end

    #
    # It will return the array containing Link objects
    # which are used for rendering the navigation per each html model page.
    # 
    # First Link object is the link to the Index page containing all makes.
    # Second Link object is the link to the parent make page containing
    # all the camera models for that particular make.
    #
    def navigation
      [IndexHtmlUnit.new.link, MakeHtmlUnitCollection.link_by_make(make)]
    end

    #
    # It will return the array containing Image objects
    # which are used for rendering the thumbnails along with the actual links
    # leading to the full-sized image, per each html model page.
    # 
    def thumbnails
      ImageCollection.by_make_model(make, model)
    end
  end


  #
  # ModelHtmlUnitCollection object holds all the ModelHtmlUnit instances.
  # It provides a method for fetching all the links to the each ModelHtmlUnit.
  # It's used to fetch links to all the distinct camera model html pages 
  # accessible via navigation located on each make page.
  #
  # It also provides a method for fetching all camera models 
  # per specific make, where make is passed as an argument.
  #
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


  #
  # Contains data needed for rendering the html page 
  # with all images captured by a specific camera make 
  #
  # It takes one argument of type String:
  #   Example:
  #
  #   > model = ModelHtmlUnit.new('Nikon')
  #   > model.filename
  #   => "make_nikon.html"
  # 
  #   > model.title
  #   => "Nikon"
  #
  class MakeHtmlUnit < Struct.new :make
    include HtmlUnit

    def filename
      generate_filename("make_#{make}")
    end

    def title
      make
    end

    #
    # It will return the array containing Link objects
    # which are used for rendering the navigation per each html make page.
    # 
    # First Link object is the link to the Index page containing all makes.
    # The remaining Link objects are the links to the model pages containing
    # all the images or the given make and the respective model.
    #
    def navigation
      [IndexHtmlUnit.new.link] + ModelHtmlUnitCollection.links_by_make(make)
    end

    #
    # It will return the array containing first [n] Image objects of the give make
    # which are used for rendering the thumbnails along with the actual links
    # leading to the full-sized image, per each html make page.
    # 
    def thumbnails
      ImageCollection.by_make_top(make, 10)
    end

    #
    # Fetch all model under the given make.
    #
    def models
      ModelHtmlUnitCollection.by_make(make)
    end
  end


  #
  # MakeHtmlUnitCollection object holds all the MakeHtmlUnit instances.
  # It provides a method for fetching all the links to the each MakeHtmlUnit.
  # It's used to fetch links to all the distinct camera make html pages 
  # accessible via navigation located on the Index page.
  #
  # It also provides a method for fetching link to the specific make page.
  # Make is passed as an argument.
  #
  class MakeHtmlUnitCollection
    @units = []

    class << self
      attr_accessor :units

      def links
        units.uniq.map { |unit| Link.new(unit.title, unit.filename) }
      end

      #
      # Tapping into the result of the find method.
      # It will be nil if the make can't be found so raise and Exception
      # since we can't work without the unit.
      #
      def link_by_make(make)
        (units.find { |unit| unit.make == make }).tap do |unit|
          raise(StandardError, 'Make not found.') if unit.nil?
          Link.new(unit.title, unit.filename)
        end
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
      @small ||= by_type('small')
    end

    def medium
      @medium ||= by_type('medium')
    end

    def large
      @large ||= by_type('large')
    end

    private
      #
      # Tapping into the result of the find method.
      # It will be nil if the key is missing so raise and Exception
      # since we can't work without the URL.
      #
      def by_type(type)
        (types['url'].find { |url| url['@type'] == type }).tap do |url|
          raise(StandardError, 'URL details are missing.') if url.nil?
        end['$']
      end
  end


  #
  # Image object holds the basic image details extracted from EXIF info
  # needed to properly handle it on Make and Model pages.
  # 
  # It provides `url` method to fetch the URLs for all image sizes,
  # which is later used for rendering thumbnails and links to the
  # full-sized images.
  #
  class Image < Struct.new :work
      UNKNOWN = 'Unknown'

    def filename
      @filename ||= work['filename']['$']
    end

    def make
      if exif['make']
        text = exif['make']['$']
        @make ||= text.empty? ? UNKNOWN : text
      else
        UNKNOWN
      end
    end

    def model
      if exif['model']
        text = exif['model']['$']
        @model ||= text.empty? ? UNKNOWN : text
      else
        UNKNOWN
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
    #
    # It groups all Image objects and provides methods
    # for fetching by image details such as make and model,
    # as well as methods for fetching make names for the purpose of
    # constructing navigation links.
    #
    @images = []

    class << self
      attr_accessor :images
      #
      # Fetch first [n] objects in the collection.
      #
      def get_any_top(number)
        images.take(number)
      end

      #
      # Fetch all objects belonging to a certain make.
      # For example, all images captured by Nikon camera.
      #
      def by_make(make)
        images.select { |image| image.make == make }
      end

      #
      # Fetch first [n] objects belonging to a certain make.
      # For example, first 10 images captured by Nikon camera.
      #
      #   > ImageCollection.by_make_top('Nikon', 10)
      #
      def by_make_top(make, number)
        by_make(make).take(number)
      end

      #
      # Fetch all objects belonging to a certain make 
      # and one of their camera models.
      # For example, all images captured by Nikon camera,
      # more specifically, Nikon D7100.
      #
      # Example:
      #   > ImageCollection.by_make_model('Nikon', 'Nikon D7100')
      #
      def by_make_model(make, model)
        by_make(make).select { |image| image.model == model }
      end

      #
      # Fetch all make names. It returns an Array of Strings.
      #
      # Example:
      #   > ImageCollection.all_makes
      #   => ["Nikon", "Canon", "Olympus", "Pentax",...]
      #
      def all_makes
        images.map(&:make)
      end

      #
      # Fetch all camera model names belonging to a specific camera make. 
      # It returns an Array of Strings.
      #
      # Example:
      #   > ImageCollection.all_models_by_make('Nikon')
      #   => ["Nikon D3100", "Nikon D5100", "Nikon D7100", "Nikon D3",...]
      #
      def all_models_by_make(make)
        by_make(make).map(&:model)
      end
    end
  end
end


if __FILE__ == $0
  raise(ArgumentError, 'Missing arguments.') if ARGV.size < 2
  
  input_file_path       = File.absolute_path(ARGV[0])
  output_directory_path = File.absolute_path(ARGV[1])

  raise(ArgumentError, 'File does not exists.') unless File.exist?(input_file_path)
  raise(ArgumentError, 'Output directory does not exists.') unless File.directory?(output_directory_path)
    
  RedBubble::HtmlGenerator.new(input_file_path, output_directory_path)
end
