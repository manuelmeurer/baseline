# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Baseline::NavbarComponent, type: :component do
  describe '#call' do
    context 'with basic configuration' do
      let(:component) { described_class.new }
      
      subject { render_inline(component) { 'Test content' } }

      it 'renders a nav element with default classes' do
        expect(subject.css('nav').first['class']).to include('navbar')
        expect(subject.css('nav').first['class']).to include('navbar-dark')
        expect(subject.css('nav').first['class']).to include('navbar-expand-lg')
      end

      it 'includes the content' do
        expect(subject.text).to include('Test content')
      end
    end

    context 'with custom options' do
      let(:component) do
        described_class.new(
          sticky: true,
          container: :lg,
          expand_at: :md,
          color_scheme: :light,
          bg: :primary,
          brand: 'My App',
          brand_url: '/home'
        )
      end
      
      subject { render_inline(component) { 'Custom content' } }

      it 'renders with sticky positioning' do
        expect(subject.css('nav').first['class']).to include('sticky-top')
      end

      it 'renders with light color scheme' do
        expect(subject.css('nav').first['class']).to include('navbar-light')
      end

      it 'renders with primary background' do
        expect(subject.css('nav').first['class']).to include('bg-primary')
      end

      it 'renders with medium expand breakpoint' do
        expect(subject.css('nav').first['class']).to include('navbar-expand-md')
      end

      it 'renders with container-lg wrapper' do
        expect(subject.css('nav .container-lg')).to be_present
      end

      it 'renders the brand with correct link' do
        brand_link = subject.css('nav .navbar-brand').first
        expect(brand_link.text).to eq('My App')
        expect(brand_link['href']).to eq('/home')
      end

      it 'includes the custom content' do
        expect(subject.text).to include('Custom content')
      end
    end

    context 'with component block usage' do
      let(:component) { described_class.new }
      
      subject do
        render_inline(component) do |c|
          c.navbar_collapse do
            c.navbar_group(class: 'm-auto') do
              c.navbar_item('Home', '/') +
              c.navbar_item('About', '/about')
            end
          end
        end
      end

      it 'renders navbar collapse structure' do
        expect(subject.css('.navbar-toggler')).to be_present
        expect(subject.css('.navbar-collapse')).to be_present
      end

      it 'renders navbar group with custom class' do
        group = subject.css('.navbar-nav.m-auto').first
        expect(group).to be_present
      end

      it 'renders navbar items' do
        items = subject.css('.nav-item .nav-link')
        expect(items.length).to eq(2)
        expect(items.first.text).to eq('Home')
        expect(items.first['href']).to eq('/')
        expect(items.last.text).to eq('About')
        expect(items.last['href']).to eq('/about')
      end
    end
  end
end