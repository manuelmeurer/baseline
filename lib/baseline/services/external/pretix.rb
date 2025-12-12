# frozen_string_literal: true

module Baseline
  module External
    class Pretix < ::External::Base
      BASE_URL = "https://pretix.eu/api/v1".freeze

      DuplicateVoucherError = Class.new(Error)

      # Orders

      # https://docs.pretix.eu/en/latest/api/resources/orders.html#fetching-individual-orders
      add_action :get_order do |event, id|
        request :get,
          path_with_prefix(event, "orders", id)
      end

      # https://docs.pretix.eu/dev/api/resources/orders.html#get--api-v1-organizers-(organizer)-events-(event)-orders-
      add_action :list_orders do |event_id, params = {}|
        paginate_get \
          path_with_prefix(event_id, "orders", **params)
      end

      # https://docs.pretix.eu/dev/api/resources/orders.html#post--api-v1-organizers-(organizer)-events-(event)-orders-
      add_action :create_order do |event_id, params|
        request :post,
          path_with_prefix(event_id, "orders"),
          json: params
      end

      # https://docs.pretix.eu/dev/api/resources/orders.html#patch--api-v1-organizers-(organizer)-events-(event)-orderpositions-(id)-
      add_action :update_order_position do |event_id, position_id, params|
        request :patch,
          path_with_prefix(event_id, "orderpositions", position_id),
          json: params
      end

      # Invoices

      # https://docs.pretix.eu/en/latest/api/resources/invoices.html#list-of-all-invoices
      add_action :list_invoices do |event_id, params = {}|
        paginate_get \
          path_with_prefix(event_id, "invoices"),
          params
      end

      # https://docs.pretix.eu/en/latest/api/resources/invoices.html#fetching-individual-invoices
      add_action :get_invoice do |event_id, id|
        request :get,
          path_with_prefix(event_id, "invoices", id)
      end

      # https://docs.pretix.eu/en/latest/api/resources/invoices.html#get--api-v1-organizers-(organizer)-events-(event)-invoices-(number)-download-
      add_action :download_invoice do |event_id, invoice_number|
        path_with_prefix(
          event_id,
          "invoices",
          invoice_number,
          "download"
        ).then {
          request :get, _1
        }
      end

      # Vouchers

      # https://docs.pretix.eu/dev/api/resources/vouchers.html#get--api-v1-organizers-(organizer)-events-(event)-vouchers-
      add_action :list_vouchers do |event_id, params = {}|
        paginate_get \
          path_with_prefix(event_id, "vouchers", **params)
      end

      # https://docs.pretix.eu/dev/api/resources/vouchers.html#post--api-v1-organizers-(organizer)-events-(event)-vouchers-
      add_action :create_voucher do |event_id, params|
        request :post,
          path_with_prefix(event_id, "vouchers"),
          json: params
      rescue RequestError => error
        if error.message.include?("already exists")
          raise DuplicateVoucherError
        else
          raise error
        end
      end

      # https://docs.pretix.eu/dev/api/resources/vouchers.html#patch--api-v1-organizers-(organizer)-events-(event)-vouchers-(id)-
      add_action :update_voucher do |event_id, voucher_id, params|
        request :patch,
          path_with_prefix(event_id, "vouchers", voucher_id),
          json: params
      end

      # https://docs.pretix.eu/dev/api/resources/vouchers.html#delete--api-v1-organizers-(organizer)-events-(event)-vouchers-(id)-
      add_action :delete_voucher do |event_id, voucher_id|
        request :delete,
          path_with_prefix(event_id, "vouchers", voucher_id)
      end

      # Items

      # https://docs.pretix.eu/dev/api/resources/items.html#get--api-v1-organizers-(organizer)-events-(event)-items-
      add_action :list_items do |event_id|
        paginate_get \
          path_with_prefix(event_id, "items")
      end

      # https://docs.pretix.eu/dev/api/resources/items.html#get--api-v1-organizers-(organizer)-events-(event)-items-(id)-
      add_action :get_item do |event_id, item_id|
        request :get,
          path_with_prefix(event_id, "items", item_id)
      end

      # Quotas

      # https://docs.pretix.eu/dev/api/resources/quotas.html#get--api-v1-organizers-(organizer)-events-(event)-quotas-
      add_action :list_quotas do |event_id|
        paginate_get \
          path_with_prefix(event_id, "quotas")
      end

      # Gift cards

      # https://docs.pretix.eu/dev/api/resources/giftcards.html#post--api-v1-organizers-(organizer)-giftcards-
      add_action :create_gift_card do |params|
        request :post,
          path_with_prefix(nil, "giftcards"),
          json: params
      end

      # Campaigns

      # https://docs.pretix.eu/dev/api/resources/campaigns.html#get--api-v1-organizers-(organizer)-events-(event)-campaigns-(id)-
      add_action :get_campaign, return_unless_prod: ->(*args) { { code: "dummy_#{args.join("_")}" } } do |event_id, campaign_id|
        request :get,
          path_with_prefix(event_id, "campaigns", campaign_id)
      end

      # https://docs.pretix.eu/dev/api/resources/campaigns.html#post--api-v1-organizers-(organizer)-events-(event)-campaigns-
      add_action :create_campaign do |event_id, params|
        request :post,
          path_with_prefix(event_id, "campaigns"),
          json: params
      end

      # Item variations

      # https://docs.pretix.eu/dev/api/resources/item_variations.html#get--api-v1-organizers-(organizer)-events-(event)-items-(item)-variations-
      add_action :list_item_variations do |event_id, item_id|
        paginate_get \
          path_with_prefix(event_id, "items", item_id, "variations")
      end

      private

        def request_auth = "Token #{Rails.application.env_credentials.pretix_token!}"

        def next_url_and_params(response, url, params)
          if next_url = response[:next]&.delete_prefix(BASE_URL)
            [next_url, params]
          end
        end

        def path_with_prefix(event_id = nil, *path_parts, **params)
          path = File.join("organizers", organizer)
          if event_id
            path = File.join(path, "events", event_id)
          end
          File.join(
            path,
            *path_parts.map(&:to_s),
            "" # Make sure the path has a trailing slash.
          ).then {
            Addressable::URI.new(
              path:         _1,
              query_values: params.presence
            ).to_s
          }
        end
    end
  end
end
