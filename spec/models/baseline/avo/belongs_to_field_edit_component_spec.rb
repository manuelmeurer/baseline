# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Avo::Fields::BelongsToField::EditComponent", :avo do
  subject(:component) { ::Avo::Fields::BelongsToField::EditComponent.allocate }

  let(:base_class) { BaseResource }
  let(:descendant_class) { DescendantResource }
  let(:another_descendant_class) { AnotherDescendantResource }
  let(:record_class) do
    Class.new do
      def initialize(attributes = {})
        @attributes = attributes.stringify_keys
      end

      def [](key)
        @attributes[key.to_s]
      end

      def []=(key, value)
        @attributes[key.to_s] = value
      end

      def messageable_type = self["messageable_type"]
      def messageable_id   = self["messageable_id"]
    end
  end
  let(:record) do
    record_class.new(
      messageable_type: base_class.name,
      messageable_id: nil
    )
  end
  let(:messageable) { descendant_class.new.tap { _1.define_singleton_method(:id) { 1879 } } }
  let(:field) do
    instance_double(
      Avo::Fields::BelongsToField,
      foreign_key: "messageable",
      types: [descendant_class],
      value: messageable
    )
  end
  let(:resource) { instance_double(Avo::Resources::Base, record:) }

  before do
    stub_const("BaseResource", Class.new)
    stub_const("DescendantResource", Class.new(BaseResource))
    stub_const("AnotherDescendantResource", Class.new(BaseResource))

    component.instance_variable_set(:@field, field)
    component.instance_variable_set(:@resource, resource)
  end

  describe "#polymorphic_class" do
    it "normalizes a stored STI base class to the configured descendant class" do
      expect(component.send(:polymorphic_class)).to eq("DescendantResource")
      expect(record.messageable_type).to eq("DescendantResource")
    end
  end

  describe "#polymorphic_id" do
    it "backfills the polymorphic id from the selected record" do
      component.send(:polymorphic_class)

      expect(component.send(:polymorphic_id)).to eq(1879)
      expect(record.messageable_id).to eq(1879)
    end
  end

  describe "#polymorphic_record" do
    it "reuses the already loaded descendant record" do
      expect(component.send(:polymorphic_record)).to eq(messageable)
    end
  end

  context "when the STI mapping is ambiguous" do
    let(:field) do
      instance_double(
        Avo::Fields::BelongsToField,
        foreign_key: "messageable",
        types: [descendant_class, another_descendant_class],
        value: nil
      )
    end
    let(:record) { record_class.new(messageable_type: base_class.name, messageable_id: 1879) }

    it "keeps the stored base class" do
      expect(component.send(:polymorphic_class)).to eq("BaseResource")
      expect(record.messageable_type).to eq("BaseResource")
    end
  end
end
