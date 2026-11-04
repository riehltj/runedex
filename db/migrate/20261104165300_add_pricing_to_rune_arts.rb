class AddPricingToRuneArts < ActiveRecord::Migration[8.1]
  def change
    add_column :rune_arts, :tcgplayer_product_id, :integer
    add_column :rune_arts, :market_price, :decimal, precision: 10, scale: 2
    add_column :rune_arts, :low_price, :decimal, precision: 10, scale: 2
    add_column :rune_arts, :price_updated_at, :datetime
  end
end
