# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alchemy::ElementsFinder do
  let(:finder) { described_class.new(options) }
  let(:options) { {} }

  describe "#elements" do
    subject { finder.elements }

    let(:page) { create(:alchemy_page, :public) }
    let!(:visible_element) { create(:alchemy_element, public: true, page: page) }
    let!(:hidden_element) { create(:alchemy_element, public: false, page: page) }

    context "without page given" do
      it do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "with page object given" do
      subject { finder.elements(page: page) }

      it "returns all public elements from page" do
        is_expected.to eq([visible_element])
      end

      context "with multiple ordered elements" do
        let!(:element_2) do
          create(:alchemy_element, public: true, page: page).tap { |el| el.update_columns(position: 3) }
        end

        let!(:element_3) do
          create(:alchemy_element, public: true, page: page).tap { |el| el.update_columns(position: 2) }
        end

        it "returns elements ordered by position" do
          is_expected.to eq([visible_element, element_3, element_2])
        end
      end

      context "with fixed elements present" do
        let!(:fixed_element) { create(:alchemy_element, :fixed, page: page) }

        it "does not include fixed elements" do
          is_expected.to_not include(fixed_element)
        end

        context "with options[:fixed] set to true" do
          let(:options) do
            { fixed: true }
          end

          it "includes only fixed elements" do
            is_expected.to eq([fixed_element])
          end
        end
      end

      context "with nested elements present" do
        let!(:nested_element) { create(:alchemy_element, :nested, page: page) }

        it "does not include nested elements" do
          is_expected.to_not include(nested_element)
        end
      end

      context "with options[:only] given" do
        let(:options) do
          { only: "article" }
        end

        it "returns only the elements with that name" do
          is_expected.to eq([visible_element])
        end
      end

      context "with options[:except] given" do
        let(:options) do
          { except: "article" }
        end

        it "does not return the elements with that name" do
          is_expected.to eq([])
        end
      end

      context "with options[:offset] given" do
        let(:options) do
          { offset: 2 }
        end

        let!(:visible_element_2) { create(:alchemy_element, public: true, page: page) }
        let!(:visible_element_3) { create(:alchemy_element, public: true, page: page) }

        it "returns elements beginning from that offset" do
          is_expected.to eq([visible_element_3])
        end
      end

      context "with options[:count] given" do
        let(:options) do
          { count: 1 }
        end

        let!(:visible_element_2) { create(:alchemy_element, public: true, page: page) }

        it "returns elements beginning from that offset" do
          is_expected.to eq([visible_element])
        end
      end

      context "with options[:reverse] given" do
        let(:options) do
          { reverse: true }
        end

        let!(:visible_element_2) { create(:alchemy_element, public: true, page: page) }

        it "returns elements in reverse order" do
          is_expected.to eq([visible_element_2, visible_element])
        end
      end

      context "with options[:random] given" do
        let(:options) do
          { random: true }
        end

        let(:random_function) do
          case ActiveRecord::Base.connection_config[:adapter]
          when "postgresql", "sqlite3"
            "RANDOM()"
          else
            "RAND()"
          end
        end

        it "returns elements in random order" do
          expect_any_instance_of(ActiveRecord::Relation).to \
            receive(:reorder).with(random_function).and_call_original
          subject
        end
      end
    end
  end
end
