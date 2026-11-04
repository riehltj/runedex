# Seeds the alt-art and Nexus Night promo runes for every domain in Riftbound sets 1-5.
# Idempotent: records are keyed on set + collector number, so re-running updates in place.
#
# Card data and images: https://riftbound.org/cards/nexus-night-promo-cards

IMAGE_BASE = "https://riftbound.org/storage/cards".freeze

DOMAIN_ORDER = RuneArt::DOMAINS.keys # Fury, Calm, Mind, Body, Chaos, Order -> R01..R06

SETS = [
  { name: "Origins",      code: "OGN", released_on: "2025-10-31", origins_numbers: %w[007 042 089 126 166 214] },
  { name: "Spiritforged", code: "SFD", released_on: "2026-02-13" },
  { name: "Unleashed",    code: "UNL", released_on: "2026-05-08",
    promo_note: "Reuses the Spiritforged Nexus Night rune art." },
  # riftbound.org only has the Calm alt-art image; others come from PriceCharting or are blank (placeholder).
  { name: "Vendetta",     code: "VEN", released_on: "2026-07-31",
    alt_images: {
      "Fury"  => nil,
      "Mind"  => "https://storage.googleapis.com/images.pricecharting.com/upx6yhqphuyfdy3d/1600.jpg",
      "Body"  => "https://storage.googleapis.com/images.pricecharting.com/erztez2vkh3b5ule/1600.jpg",
      "Chaos" => nil,
      "Order" => nil
    } },
  { name: "Radiance",     code: "RAD", released_on: "2026-10-23", promo_artist: "Jincheng Guo" }
].freeze

def upsert_rune(attrs)
  rune = RuneArt.find_or_initialize_by(set_name: attrs[:set_name], collector_number: attrs[:collector_number])
  rune.update!(attrs.compact) # nil values don't clobber images/notes you've added by hand
end

SETS.each do |set|
  code = set[:code]
  slug = code.downcase

  DOMAIN_ORDER.each_with_index do |domain, i|
    if set[:origins_numbers]
      num = set[:origins_numbers][i]
      alt_number,   alt_img   = "#{code}-#{num}a/298",   "#{slug}/#{slug}-#{num}a-298"
      promo_number, promo_img = "#{code}-#{num}b/298 P", "prm/#{slug}-#{num}b-298-p"
    else
      r = format("r%02d", i + 1)
      alt_number,   alt_img   = "#{code}-#{r.upcase}a",    "#{slug}/#{slug}-#{r}a"
      promo_number, promo_img = "#{code}-#{r.upcase}b P",  "prm/#{slug}-#{r}b-p"
    end

    alt_images = set[:alt_images] || {}
    upsert_rune(
      domain: domain, set_name: set[:name], variant: "Alternate Art",
      title: "#{domain} Rune (Alt Art)", source: "#{set[:name]} booster (foil)",
      notes: set.dig(:alt_notes, domain),
      collector_number: alt_number, released_on: set[:released_on],
      image_url: alt_images.key?(domain) ? alt_images[domain] : "#{IMAGE_BASE}/#{alt_img}.webp"
    )

    upsert_rune(
      domain: domain, set_name: set[:name], variant: "Promo",
      title: "#{domain} Rune (Nexus Night)", source: "Nexus Night",
      artist: set[:promo_artist], notes: set[:promo_note],
      collector_number: promo_number, released_on: set[:released_on],
      image_url: "#{IMAGE_BASE}/#{promo_img}.webp"
    )
  end
end

puts "Rune arts: #{RuneArt.count}"
