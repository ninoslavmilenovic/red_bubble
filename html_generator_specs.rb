# encoding: utf-8

require 'rspec'
require_relative 'html_generator'

describe RedBubble do 
  it 'has a VERSION constant' do
    expect(subject.const_get('VERSION')).not_to be_empty
  end

  let(:file_path) { File.expand_path(File.join(File.dirname(__FILE__), 'works.xml')) }
  let(:output_path) { File.expand_path(File.join(File.dirname(__FILE__), 'static_html')) }
  let(:html_generator) { RedBubble::HtmlGenerator.new(file_path, output_path) }

  before(:each) do
    Object.send(:remove_const, 'RedBubble')
    load 'html_generator.rb'
  end

  describe RedBubble::URL do
    describe '#initialize' do
      context 'when valid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url }.not_to raise_error }
        specify { expect(url.types).to eq(argument) }
      end

      context 'when invalid arguments' do
        context 'when invalid type' do
          let(:argument) { Array.new }
          let(:url) { RedBubble::URL.new(argument) }

          specify { expect { url }.to raise_error(ArgumentError, 'Invalid Type. Hash expected.') }
        end

        context 'when key is missing' do
          let(:argument) { { 'url invalid' =>  [] } }
          let(:url) { RedBubble::URL.new(argument) }

          specify { expect { url }.to raise_error(StandardError, 'Hash is mising `url` key.') }
        end

        context 'when value is invalid' do
          let(:argument) { { 'url' => String.new } }
          let(:url) { RedBubble::URL.new(argument) }

          specify { expect { url }.to raise_error(StandardError, '`url` key should containt an array.') }
        end
      end
    end

    describe '#small' do
      context 'when valid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.small }.not_to raise_error }
        specify { expect(url.small).to eq('http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg') }
      end

      context 'when invalid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.small }.to raise_error(StandardError, 'URL details are missing.') }
      end
    end

    describe '#medium' do
      context 'when valid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.medium }.not_to raise_error }
        specify { expect(url.medium).to eq('http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg') }
      end

      context 'when invalid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.medium }.to raise_error(StandardError, 'URL details are missing.') }
      end
    end

    describe '#large' do
      context 'when valid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
              {"@type" => "large",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg" }
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.large }.not_to raise_error }
        specify { expect(url.large).to eq('http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg') }
      end

      context 'when invalid arguments' do
        let(:argument) do 
          { "url" => [
              {"@type" => "small",  "$" => "http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg" },
              {"@type" => "medium", "$" => "http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg" },
            ]
          } 
        end
        let(:url) { RedBubble::URL.new(argument) }

        specify { expect { url.large }.to raise_error(StandardError, 'URL details are missing.') }
      end
    end
  end

  describe RedBubble::ModelHtmlUnit do
    describe '#make' do
      context 'when valid arguments' do
        let(:model) { RedBubble::ModelHtmlUnit.new 'NIKON CORPORATION', 'NIKON D80' }

        specify { expect(model.make).to eq('NIKON CORPORATION')  }
      end
    end

    describe '#model' do
      context 'when valid arguments' do
        let(:model) { RedBubble::ModelHtmlUnit.new 'NIKON CORPORATION', 'NIKON D80' }

        specify { expect(model.model).to eq('NIKON D80') }
      end
    end

    describe '#filename' do
      context 'when valid arguments' do
        let(:model) { RedBubble::ModelHtmlUnit.new 'NIKON CORPORATION', 'NIKON D80' }

        specify { expect(model.filename).to eq('model_nikon_corporation_nikon_d80.html') }
      end
    end

    describe '#title' do
      context 'when valid arguments' do
        let(:model) { RedBubble::ModelHtmlUnit.new 'NIKON CORPORATION', 'NIKON D80' }

        specify { expect(model.title).to eq('NIKON CORPORATION | NIKON D80') }
      end

      context 'with file example' do
        let!(:html_generator) { RedBubble::HtmlGenerator.new(file_path, output_path) }
        let!(:make) { RedBubble::MakeHtmlUnitCollection.units.first }
        let!(:model) { make.models.first }

        specify { expect(model.title).to eq('NIKON CORPORATION | NIKON D80') }
      end
    end

    describe '#navigation' do
      context 'with file example' do
        let!(:html_generator) { RedBubble::HtmlGenerator.new(file_path, output_path) }
        let!(:make) { RedBubble::MakeHtmlUnitCollection.units.first }
        let!(:model) { make.models.first }

        specify { expect(model.navigation.size).to eq(2) }
        specify { expect(model.navigation[1].title).to eq('NIKON CORPORATION') }
        specify { expect(model.navigation[1].filename).to eq('make_nikon_corporation.html') }
      end
    end
  end
end
