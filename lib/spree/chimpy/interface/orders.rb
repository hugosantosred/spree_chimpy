module Spree::Chimpy
  module Interface
    class Orders
      delegate :log, to: Spree::Chimpy

      def initialize
        @api = Spree::Chimpy.api
      end

      def add(order)
        log "Adding order #{order.number}"

        response = @api.ecomm.order_add(hash(order))
        log "Order #{order.number} added successfully!" if response["complete"]
        response["complete"]
      end

      def remove(order)
        log "Attempting to remove order #{order.number}"

        response = @api.ecomm.order_del(Spree::Chimpy::Config.store_id, order.number)
        log "Order #{order.number} removed successfully!" if response["complete"]
        response["complete"]
      end

      def sync(order)
        remove(order) rescue nil
        add(order)
      end

    private
      def hash(order)
        source = order.source
        root_taxon = Spree::Taxon.find_by_parent_id(nil)

        items = order.line_items.map do |line|
          # MC can only associate the order with a single category: associate the order with the category right below the root level taxon
          variant = line.variant
          taxon = variant.product.taxons.map(&:self_and_ancestors).flatten.uniq.detect { |t| t.parent == root_taxon }

          {product_id: variant.id,
           sku: variant.sku,
           product_name: variant.name,
           category_id: taxon ? taxon.id : 999999,
           category_name: taxon ? taxon.name : "Uncategorized",
           cost: variant.price.to_f,
           qty: line.quantity}
        end

        data = {
          id: order.number,
          email: order.email,
          total: order.item_total.to_f,
          order_date: order.completed_at.strftime('%Y-%m-%d'),
          shipping: order.ship_total.to_f,
          tax: order.tax.to_f,
          store_name: Spree::Config.site_name,
          store_id: Spree::Chimpy::Config.store_id,
          items: items
        }

        if source
          data[:email_id] = source.email_id
          data[:campaign_id] = source.campaign_id
        end

        data
      end

    end
  end
end
