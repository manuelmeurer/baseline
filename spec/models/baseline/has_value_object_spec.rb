# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::HasValueObject do
  let(:address_class) do
    Data.define(:street, :city) do
      def self.from_h(attributes)
        new(
          street: attributes["street"] || attributes[:street],
          city:   attributes["city"] || attributes[:city]
        )
      end

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
      stub_const("ValueObjectVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObject[:object_changes, value_object_class]
    end
  end

  it "casts hashes into value objects" do
    record = record_class.new(
      object_changes: {
        "street" => "Main Street",
        "city"   => "Berlin"
      }
    )

    expect(record.object_changes).to eq(
      address_class.new(street: "Main Street", city: "Berlin")
    )
  end

  it "serializes value objects into the model column" do
    address = address_class.new(street: "Main Street", city: "Berlin")

    record = record_class.create!(
      event:          "create",
      item_id:        1,
      item_type:      "User",
      object_changes: address
    )

    expect(record_class.find(record.id).object_changes).to eq(address)
  end

  it "assigns value objects from nested attributes" do
    record = record_class.new

    record.object_changes_attributes = {
      "street" => "Main Street",
      "city"   => "Berlin"
    }

    expect(record.object_changes).to eq(
      address_class.new(street: "Main Street", city: "Berlin")
    )
  end

  it "instantiates value objects with keyword initializers" do
    data_address_class = Data.define(:street, :city)

    data_record_class = Class.new(ApplicationRecord).tap do |klass|
      stub_const("DataAddressVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObject[:object_changes, data_address_class]
    end

    record = data_record_class.new(
      object_changes: {
        "street" => "Main Street",
        "city"   => "Berlin"
      }
    )

    expect(record.object_changes).to eq(
      data_address_class.new(street: "Main Street", city: "Berlin")
    )
  end

  it "clears value objects when nested attributes are blank" do
    record = record_class.new

    record.object_changes_attributes = {
      "street" => "",
      "city"   => ""
    }

    expect(record.object_changes).to be_nil
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
    stub_const("ValidatedAddress", validated_address_class)

    validated_record_class = Class.new(ApplicationRecord).tap do |klass|
      stub_const("ValidatedAddressVersion", klass)
      klass.table_name = "versions"
      klass.include Baseline::HasValueObject[:object_changes, ValidatedAddress]
    end

    record = validated_record_class.new(object_changes: { "street" => "" })

    expect(record).not_to be_valid
    expect(record.errors).to be_of_kind(:object_changes, :invalid)
  end

  it "works with ActiveModel models without a database column" do
    value_object_class = address_class

    form_class = Class.new do
      include ActiveModel::Model

      include Baseline::HasValueObject[:address, value_object_class]
    end

    form = form_class.new(
      address: {
        "street" => "Main Street",
        "city"   => "Berlin"
      }
    )

    expect(form.address).to eq(
      address_class.new(street: "Main Street", city: "Berlin")
    )
  end
end
