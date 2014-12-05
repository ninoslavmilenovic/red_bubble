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
