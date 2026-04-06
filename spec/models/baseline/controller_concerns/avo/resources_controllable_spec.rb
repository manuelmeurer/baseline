# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Avo::ResourcesControllable do
  subject(:assign_via_polymorphic_association_to_record) do
    controller.send(:assign_via_polymorphic_association_to_record)
  end

  let(:controller_class) do
    Class.new(ActionController::Base) do
      include Baseline::Avo::ResourcesControllable
    end
  end

  let(:controller) { controller_class.new }

  before do
    controller.instance_variable_set(:@record, record)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(params))
  end

  context "with a polymorphic belongs_to association" do
    let(:record) { Task.new }
    let(:user) { create(:user, :male) }
    let(:params) do
      {
        via_relation: "taskable",
        via_relation_class: "User",
        via_record_id: user.id
      }
    end
    let(:resource_manager) { instance_double(Avo::Resources::ResourceManager) }
    let(:resource) { instance_double("Avo resource") }

    before do
      allow(Avo).to receive(:resource_manager).and_return(resource_manager)
      allow(resource_manager).to receive(:get_resource_by_model_class).with("User").and_return(resource)
      allow(resource).to receive(:find_record).with(user.id, params: controller.params).and_return(user)
    end

    it "assigns the via record through the polymorphic association" do
      assign_via_polymorphic_association_to_record

      expect(record.taskable).to eq(user)
      expect(record.taskable_type).to eq("User")
      expect(record.taskable_id).to eq(user.id)
    end
  end

  context "with a non-polymorphic belongs_to association" do
    let(:record) { UserSubscription.new }
    let(:user) { create(:user, :male) }
    let(:params) do
      {
        via_relation: "user",
        via_relation_class: "User",
        via_record_id: user.id
      }
    end

    it "leaves the record unchanged" do
      expect(Avo).not_to receive(:resource_manager)

      assign_via_polymorphic_association_to_record

      expect(record.user).to be_nil
    end
  end

  context "without nested via params" do
    let(:record) { Task.new }
    let(:params) { {} }

    it "does nothing" do
      expect(Avo).not_to receive(:resource_manager)

      assign_via_polymorphic_association_to_record

      expect(record.taskable).to be_nil
    end
  end
end
