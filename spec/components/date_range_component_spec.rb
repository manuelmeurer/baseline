# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::DateRangeComponent do
  describe "#call" do
    context "with same month dates" do
      it "formats with en dash and omits redundant month/year" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 6, 13)
        )

        expect(component.call).to eq("June 12–13, 2026")
      end
    end

    context "with different months, same year" do
      it "formats with en dash and omits redundant year" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 7, 13)
        )

        expect(component.call).to eq("June 12–July 13, 2026")
      end
    end

    context "with different years" do
      it "formats with en dash and full dates" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2027, 7, 13)
        )

        expect(component.call).to eq("June 12, 2026–July 13, 2027")
      end
    end

    context "with same day" do
      it "returns single date" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 6, 12)
        )

        expect(component.call).to eq("June 12, 2026")
      end
    end

    context "with short format" do
      it "uses abbreviated month names" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 6, 13),
          format:     :short
        )

        expect(component.call).to eq("Jun 12–13, 2026")
      end

      it "works with different months" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 7, 13),
          format:     :short
        )

        expect(component.call).to eq("Jun 12–Jul 13, 2026")
      end
    end

    context "with blank dates" do
      it "returns nil for nil start_date" do
        component = described_class.new(
          start_date: nil,
          end_date:   Date.new(2026, 6, 13)
        )

        expect(component.call).to be_nil
      end

      it "returns nil for nil end_date" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   nil
        )

        expect(component.call).to be_nil
      end
    end

    context "with string dates" do
      it "parses and formats correctly" do
        component = described_class.new(
          start_date: "2026-06-12",
          end_date:   "2026-06-13"
        )

        expect(component.call).to eq("June 12–13, 2026")
      end
    end

    context "with German locale" do
      around { |example| I18n.with_locale(:de) { example.run } }

      it "formats same day" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 6, 12)
        )

        expect(component.call).to eq("12. Juni 2026")
      end

      it "formats same month with day range" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 6, 13)
        )

        expect(component.call).to eq("12.–13. Juni 2026")
      end

      it "formats different months with spaced en dash" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2026, 7, 13)
        )

        expect(component.call).to eq("12. Juni – 13. Juli 2026")
      end

      it "formats different years with spaced en dash" do
        component = described_class.new(
          start_date: Date.new(2026, 6, 12),
          end_date:   Date.new(2027, 7, 13)
        )

        expect(component.call).to eq("12. Juni 2026 – 13. Juli 2027")
      end

      context "with short format" do
        it "uses abbreviated month names" do
          component = described_class.new(
            start_date: Date.new(2026, 6, 12),
            end_date:   Date.new(2026, 6, 13),
            format:     :short
          )

          expect(component.call).to eq("12.–13. Jun 2026")
        end

        it "works with different months" do
          component = described_class.new(
            start_date: Date.new(2026, 6, 12),
            end_date:   Date.new(2026, 7, 13),
            format:     :short
          )

          expect(component.call).to eq("12. Jun – 13. Jul 2026")
        end
      end
    end
  end
end
