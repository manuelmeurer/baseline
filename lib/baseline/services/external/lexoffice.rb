# frozen_string_literal: true

module Baseline
  module External
    class Lexoffice < ::External::Base
      BASE_URL  = "https://api.lexoffice.io/v1".freeze
      PAGE_SIZE = 250.freeze

      class << self
        def voucher_url(id) = "https://app.lexoffice.de/vouchers#!/VoucherView/Invoice/#{id}"
        def contact_url(id) = "https://app.lexoffice.de/contacts/#{id}"
      end

      # Invoices

      # https://developers.lexoffice.io/docs/#invoices-endpoint-retrieve-an-invoice
      add_action :get_invoice do |id|
        request :get, "invoices/#{id}"
      end

      # https://developers.lexoffice.io/docs/#invoices-endpoint-render-an-invoice-document-pdf
      add_action :get_invoice_document do |id|
        request :get, "invoices/#{id}/document"
      end

      # https://developers.lexoffice.io/docs/#invoices-endpoint-create-an-invoice
      add_action :create_invoice do |params|
        request(
          :post,
          "invoices",
          params: { finalize: true },
          json:   params
        ).fetch(:id)
      end

      # Contacts

      # https://developers.lexoffice.io/docs/#contacts-endpoint-retrieve-a-contact
      add_action :get_contact do |id|
        request :get, "contacts/#{id}"
      end

      # https://developers.lexoffice.io/docs/#contacts-endpoint-filtering-contacts
      add_action :list_contacts do |params|
        paginate_get \
          "contacts",
          params
      end

      # https://developers.lexoffice.io/docs/#contacts-endpoint-create-a-contact
      add_action :create_contact do |roles, params|
        params = params.merge(
          roles:   Array(roles).index_with { Hash.new },
          version: 0
        )
        request(:post, "contacts", json: params)
          .fetch(:id)
      end

      # https://developers.lexoffice.io/docs/#contacts-endpoint-update-a-contact
      add_action :update_contact do |id, params|
        contact = call(:get_contact, id)
        params = contact
          .slice(:version, :roles)
          .reverse_merge(params)

        request :put, "contacts/#{id}", json: params
      end

      # Payments

      # https://developers.lexoffice.io/docs/#payments-endpoint-retrieve-payment-information
      add_action :get_payment do |id|
        request :get, "payments/#{id}"
      end

      # Credit Notes

      # https://developers.lexoffice.io/docs/#credit-notes-endpoint-retrieve-a-credit-note
      add_action :get_credit_note do |id|
        request :get, "credit-notes/#{id}"
      end

      # https://developers.lexoffice.io/docs/#credit-notes-endpoint-render-a-credit-note-document-pdf
      add_action :get_credit_note_document do |id|
        request :get, "credit-notes/#{id}/document"
      end

      # https://developers.lexoffice.io/docs/#credit-notes-endpoint-create-a-credit-note
      add_action :create_credit_note do |params|
        if params.key?(:preceding_sales_voucher_id) && params.many?
          raise Error, "If preceding_sales_voucher_id is passed, no other params are allowed."
        end

        url_params = {
          finalize:                true,
          precedingSalesVoucherId: params.delete(:preceding_sales_voucher_id)
        }.compact

        request(
          :post,
          "credit-notes",
          params: url_params,
          json:   params
        ).fetch(:id)
      end

      # Files

      # https://developers.lexoffice.io/docs/#files-endpoint-download-a-file
      add_action :get_file do |id|
        request :get, "files/#{id}", accept: nil
      end

      # https://developers.lexoffice.io/docs/#files-endpoint-upload-a-file
      add_action :create_file do |path_or_io, type: "voucher"|
        request(
          :post,
          "files",
          form: {
            file: HTTP::FormData::File.new(path_or_io),
            type:
          }
        ).fetch(:id)
      end

      # Vouchers

      # https://developers.lexoffice.io/docs/#voucherlist-endpoint-retrieve-and-filter-voucherlist
      add_action :list_vouchers do |type: :any, status: :any, **filters|
        {
          voucherType:   type,
          voucherStatus: status
        }.transform_values {
          Array(_1).join(",")
        }.merge(filters)
          .then {
            paginate_get \
              "voucherlist",
              _1
          }
      end

      # https://developers.lexoffice.io/docs/#vouchers-endpoint-create-a-voucher
      add_action :create_voucher do |params|
        request(
          :post,
          "vouchers",
          json: params
        ).fetch(:id)
      end

      # https://developers.lexoffice.io/docs/#vouchers-endpoint-upload-a-file-to-a-voucher
      add_action :create_voucher_file do |id, path_or_io|
        request(
          :post,
          "vouchers/#{id}/files",
          form: {
            file: HTTP::FormData::File.new(path_or_io)
          }
        ).fetch(:id)
      end

      private

        def request_auth         = "Bearer #{Rails.application.env_credentials.lexoffice_api_key!}"
        def paginate_results_key = :content

        def prepare_paginate_params(params)
          params.reverse_merge(
            page: 0,
            size: PAGE_SIZE
          )
        end

        def next_url_and_params(response, url, params)
          unless response.fetch(:last)
            params[:page] += 1
            [url, params]
          end
        end
    end
  end
end
