# encoding: utf-8

require 'rspec'
require_relative 'html_generator'

describe RedBubble do 
  it 'has a VERSION constant' do
    expect(subject.const_get('VERSION')).not_to be_empty
  end

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


  describe RedBubble::HtmlUnit do
    describe '#generate_filename' do
      before do 
        class UnitHost < Struct.new :base
          include RedBubble::HtmlUnit

          def filename
            generate_filename(base)
          end
        end
        @unit = UnitHost.new('NIKON Corporation "D7100')
      end

      specify { expect(@unit.filename).to eq('nikon_corporation_d7100.html') }
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
    end

    describe '#navigation' do
      context 'when valid arguments' do
        let!(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
        let!(:make_collection) { RedBubble::MakeHtmlUnitCollection }
        let!(:model) { RedBubble::ModelHtmlUnit.new make.make, 'NIKON D80' }

        before { make_collection.units << make }

        specify do 
          expect(model.navigation).to match_array([
            RedBubble::IndexHtmlUnit.new.link, 
            make_collection.link_by_make(make.make)
          ])
        end

        specify { expect(model.navigation[0].title).to eq('Index') }
        specify { expect(model.navigation[0].filename).to eq('index.html') }
        specify { expect(model.navigation[1].title).to eq(make.title) }
        specify { expect(model.navigation[1].filename).to eq(make.filename) }
      end
    end

    describe '#thumbnails' do
      context 'when valid arguments' do
        let!(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
        let!(:make_collection) { RedBubble::MakeHtmlUnitCollection }
        let!(:model) { RedBubble::ModelHtmlUnit.new make.make, 'NIKON D80' }

        before { make_collection.units << make }

        context 'when no images are present' do
          specify do
            expect(model.thumbnails).to match_array([])
          end
        end

        context 'when images are present' do
          let!(:work1) do
            {
              "filename"=>{"$"=>"1620421.jpg"}, 
              "urls"=> {
                "url"=>[
                  {"@type"=>"small", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg"},
                  {"@type"=>"medium", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg"},
                  {"@type"=>"large", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg"}
                ]
              },
              "exif"=> {
                "model"=>{"$"=>"NIKON D80"},
                "make"=>{"$"=>"NIKON CORPORATION"}
              }
            }
          end
          let!(:image1) { RedBubble::Image.new(work1) }
          let!(:image_collection) { RedBubble::ImageCollection }

          before { image_collection.images << image1 }
          
          specify do
            expect(model.thumbnails).to match_array(RedBubble::ImageCollection.by_make_model(model.make, model.model))
          end
          specify { expect(model.thumbnails.size).to eq(1) }
          specify { expect(model.thumbnails).to match_array([image1]) }
        end
      end
    end
  end


  describe RedBubble::ModelHtmlUnitCollection do
    let(:unit1) { RedBubble::ModelHtmlUnit.new 'NIKON CORPORATION', 'NIKON D80' }
    let(:unit2) { RedBubble::ModelHtmlUnit.new 'Canon', 'Canon 5D III' }
    let(:collection) { RedBubble::ModelHtmlUnitCollection }

    before do
      collection.units << unit1
      collection.units << unit2
    end

    describe '#units' do
      specify { expect(collection.units).to match_array([unit1, unit2]) }
    end

    describe '#by_make' do
      specify { expect(collection.by_make(unit1.make)).to match_array([unit1]) }
    end

    describe '#links_by_make' do
      specify do 
        expect(collection.links_by_make(unit2.make)).to \
          match_array([RedBubble::Link.new(unit2.title, unit2.filename)])
      end
    end
  end


  describe RedBubble::MakeHtmlUnit do
    describe '#make' do
      context 'when valid arguments' do
        let(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }

        specify { expect(make.make).to eq('NIKON CORPORATION')  }
      end
    end

    describe '#filename' do
      context 'when valid arguments' do
        let(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }

        specify { expect(make.filename).to eq('make_nikon_corporation.html') }
      end
    end

    describe '#title' do
      context 'when valid arguments' do
        let(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }

        specify { expect(make.title).to eq('NIKON CORPORATION') }
      end
    end

    describe '#navigation' do
      context 'when valid arguments' do
        let!(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
        let!(:model) { RedBubble::ModelHtmlUnit.new make.make, 'NIKON D80' }
        let!(:model_collection) { RedBubble::ModelHtmlUnitCollection }

        before { model_collection.units << model }

        specify do 
          expect(make.navigation).to match_array([RedBubble::IndexHtmlUnit.new.link] \
            + model_collection.links_by_make(make.make)
          )
        end

        specify { expect(make.navigation[0].title).to eq('Index') }
        specify { expect(make.navigation[0].filename).to eq('index.html') }
        specify { expect(make.navigation[1].title).to eq(model.title) }
        specify { expect(make.navigation[1].filename).to eq(model.filename) }
      end
    end

    describe '#thumbnails' do
      context 'when valid arguments' do
        let!(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
        let!(:make_collection) { RedBubble::MakeHtmlUnitCollection }

        before { make_collection.units << make }

        context 'when no images are present' do
          specify do
            expect(make.thumbnails).to match_array([])
          end
        end

        context 'when images are present' do
          let!(:work1) do
            {
              "filename"=>{"$"=>"1620421.jpg"}, 
              "urls"=> {
                "url"=>[
                  {"@type"=>"small", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,135x135,075,f.jpg"},
                  {"@type"=>"medium", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,300x300,075,f.jpg"},
                  {"@type"=>"large", "$"=>"http://ih1.redbubble.net/work.31820.1.flat,550x550,075,f.jpg"}
                ]
              },
              "exif"=> {
                "model"=>{"$"=>"NIKON D80"},
                "make"=>{"$"=>"NIKON CORPORATION"}
              }
            }
          end
          let!(:image1) { RedBubble::Image.new(work1) }
          let!(:image_collection) { RedBubble::ImageCollection }

          before { image_collection.images << image1 }
          
          specify do
            expect(make.thumbnails).to match_array(RedBubble::ImageCollection.by_make_top(make.make, 10))
          end
          specify { expect(make.thumbnails.size).to eq(1) }
          specify { expect(make.thumbnails).to match_array([image1]) }
        end
      end
    end

    describe '#models' do
      context 'when valid arguments' do
        let!(:make) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
        let!(:model1) { RedBubble::ModelHtmlUnit.new make.make, 'NIKON D80' }
        let!(:model2) { RedBubble::ModelHtmlUnit.new make.make, 'NIKON D3100' }
        let!(:collection) { RedBubble::ModelHtmlUnitCollection }

         before do
          collection.units << model1
          collection.units << model2
         end

        specify { expect(make.models).to match_array([model1, model2]) }
      end
    end
  end


  describe RedBubble::MakeHtmlUnitCollection do
    let(:unit1) { RedBubble::MakeHtmlUnit.new 'NIKON CORPORATION' }
    let(:unit2) { RedBubble::MakeHtmlUnit.new 'Canon' }
    let(:collection) { RedBubble::MakeHtmlUnitCollection }

    before do
      collection.units << unit1
      collection.units << unit2
    end

    describe '#units' do
      specify { expect(collection.units).to match_array([unit1, unit2]) }
    end

    describe '#links' do
      specify do 
        expect(collection.links).to \
          match_array([
            RedBubble::Link.new(unit1.title, unit1.filename), 
            RedBubble::Link.new(unit2.title, unit2.filename)
          ])
      end
    end

    describe '#link_by_make' do
      specify do 
        expect(collection.link_by_make(unit2.make)).to \
          eq(RedBubble::Link.new(unit2.title, unit2.filename))
      end
    end
  end
end
