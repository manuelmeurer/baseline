# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::HasValueObjects do
  let(:address_class) do
    Data.define(:street, :city) do
      def to_h
        {
          "street" => street,
          "city"   => city
        }
      end
    end
  end

  let(:record_class) do
    value_object_class = address_class

    Class.new(ApplicationRecord).tap do |klass|
      stub_const("ValueObjectCollectionVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObjects[:object_changes, value_object_class]
    end
  end

  it "casts arrays into value objects" do
    record = record_class.new(
      object_changes: [
        {
          "street" => "Main Street",
          "city"   => "Berlin"
        }
      ]
    )

    expect(record.object_changes).to eq([
      address_class.new(street: "Main Street", city: "Berlin")
    ])
  end

  it "serializes value objects into the model column" do
    addresses = [
      address_class.new(street: "Main Street", city: "Berlin"),
      address_class.new(street: "Broadway", city: "New York")
    ]

    record = record_class.create!(
      event:          "create",
      item_id:        1,
      item_type:      "User",
      object_changes: addresses
    )

    expect(record_class.find(record.id).object_changes).to eq(addresses)
  end

  it "assigns value objects from nested attributes" do
    record = record_class.new

    record.object_changes_attributes = {
      "0" => {
        "street" => "Main Street",
        "city"   => "Berlin"
      },
      "1" => {
        "street" => "",
        "city"   => ""
      }
    }

    expect(record.object_changes).to eq([
      address_class.new(street: "Main Street", city: "Berlin")
    ])
  end

  it "preserves nil values" do
    record = record_class.new(object_changes: nil)

    expect(record.object_changes).to be_nil
    expect(record).to be_valid
  end

  it "adds value objects" do
    record = record_class.new(object_changes: [])

    address = record.add_object_change(
      "street" => "Main Street",
      "city"   => "Berlin"
    )

    expect(address).to eq(address_class.new(street: "Main Street", city: "Berlin"))
    expect(record.object_changes).to eq([address])
  end

  it "validates invalid value objects" do
    validated_address_class = Class.new do
      include ActiveModel::Model

      attr_accessor :street

      validates :street, presence: true

      def self.from_h(attributes)
        new(street: attributes["street"] || attributes[:street])
      end

      def attributes
        { "street" => street }
      end
    end
    stub_const("ValidatedCollectionAddress", validated_address_class)

    validated_record_class = Class.new(ApplicationRecord).tap do |klass|
      stub_const("ValidatedAddressCollectionVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObjects[
        :object_changes,
        ValidatedCollectionAddress
      ]
    end

    record = validated_record_class.new(object_changes: [{ "street" => "" }])

    expect(record).not_to be_valid
    expect(record.errors).to be_of_kind(:object_changes, :invalid)
  end

  it "detects duplicates" do
    duplicate_record_class = Class.new(ApplicationRecord).tap do |klass|
      stub_const("DuplicateAddressCollectionVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObjects[
        :object_changes,
        address_class,
        allow_duplicates: false
      ]
    end

    record = duplicate_record_class.new(
      object_changes: [
        { "street" => "Main Street", "city" => "Berlin" },
        { "street" => "Main Street", "city" => "Berlin" }
      ]
    )

    expect(record).not_to be_valid
    expect(record.errors).to be_of_kind(:object_changes, :has_duplicates)
  end

  it "can be included together with HasValueObject" do
    address_collection_class = address_class
    primary_address_class    = address_class

    combined_record_class = Class.new(ApplicationRecord).tap do |klass|
      stub_const("CombinedValueObjectVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObjects[
        :object_changes,
        address_collection_class
      ]
      klass.include Baseline::HasValueObject[:object, primary_address_class]
    end

    record = combined_record_class.new(
      object: {
        "street" => "Main Street",
        "city"   => "Berlin"
      },
      object_changes: [
        {
          "street" => "Broadway",
          "city"   => "New York"
        }
      ]
    )

    expect(record.object).to eq(
      address_class.new(street: "Main Street", city: "Berlin")
    )
    expect(record.object_changes).to eq([
      address_class.new(street: "Broadway", city: "New York")
    ])
  end
end
