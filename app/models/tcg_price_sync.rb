require "net/http"

# Pulls TCGplayer prices for every rune art from tcgcsv.com, a free mirror of
# TCGplayer's catalog that refreshes once a day (~20:00 UTC).
#
# Arts are matched to a TCGplayer product by set + collector number the first time,
# and the product id is saved so later syncs (and manual fixes) use it directly.
class TcgPriceSync
  BASE = "https://tcgcsv.com/tcgplayer/89".freeze # 89 = Riftbound
  PROMO_GROUP = "OPP" # "Riftbound Organized Play Promotional Cards" (Nexus Night etc.)
  SET_CODES = {
    "Origins" => "OGN", "Spiritforged" => "SFD", "Unleashed" => "UNL",
    "Vendetta" => "VEN", "Radiance" => "RAD"
  }.freeze

  Product = Struct.new(:id, :group, :name, :number, :prices, keyword_init: true)
  Result  = Struct.new(:updated, :unmatched, :as_of, keyword_init: true)

  def self.call = new.call

  def call
    as_of = Time.zone.parse(get("https://tcgcsv.com/last-updated.txt").strip) rescue Time.current
    products = load_products
    by_id = products.index_by(&:id)
    updated, unmatched = 0, []

    RuneArt.find_each do |art|
      product = by_id[art.tcgplayer_product_id] || match(art, products)
      unless product
        unmatched << art
        next
      end

      price = pick_price(product, art)
      art.update_columns(
        tcgplayer_product_id: product.id,
        market_price: price&.dig("marketPrice") || price&.dig("midPrice"),
        low_price: price&.dig("lowPrice"),
        price_updated_at: as_of
      )
      updated += 1
    end

    Rails.logger.info("[TcgPriceSync] updated #{updated}, unmatched #{unmatched.size}")
    Result.new(updated:, unmatched:, as_of:)
  end

  private

  def load_products
    groups = fetch("groups").select { |g| (SET_CODES.values + [ PROMO_GROUP ]).include?(g["abbreviation"]) }
    groups.flat_map do |g|
      prices = fetch("#{g["groupId"]}/prices").group_by { _1["productId"] }
      fetch("#{g["groupId"]}/products").filter_map do |p|
        next unless p["name"].include?("Rune")
        number = p["extendedData"].to_a.find { _1["name"] == "Number" }&.dig("value")
        Product.new(id: p["productId"], group: g["abbreviation"], name: p["name"],
                    number:, prices: prices[p["productId"]].to_a)
      end
    end
  end

  # "OGN-007a/298" -> "007a/298", "SFD-R01b P" -> "R01b"
  def normalized_number(art)
    art.collector_number.to_s.sub(/\A[A-Z]+-/, "").sub(/\s*P\z/, "").strip
  end

  def match(art, products)
    number = normalized_number(art)
    return if number.blank?

    candidates = products.select { |p| p.number.to_s.casecmp?(number) && p.name.start_with?("#{art.domain} Rune") }
    own   = candidates.select { _1.group == SET_CODES[art.set_name] }
    promo = candidates.select { _1.group == PROMO_GROUP }

    return own.first if own.one?
    # Promo group mixes sets: trust it when the number is set-specific ("007b/298")
    # or the product name names the set ("Fury Rune (Vendetta)").
    promo.find { _1.name.include?("(#{art.set_name})") } ||
      (promo.first if promo.one? && number.include?("/"))
  end

  # Alt arts and promos are foil printings; fall back to whatever has a price.
  def pick_price(product, art)
    preferred = art.variant == "Standard" ? "Normal" : "Foil"
    product.prices.find { _1["subTypeName"] == preferred && _1["marketPrice"] } ||
      product.prices.find { _1["marketPrice"] } ||
      product.prices.first
  end

  def fetch(path)
    JSON.parse(get("#{BASE}/#{path}")).fetch("results")
  end

  def get(url)
    res = Net::HTTP.get_response(URI(url), { "User-Agent" => "RuneArtTracker/1.0" })
    raise "tcgcsv #{url}: HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    res.body
  end
end
