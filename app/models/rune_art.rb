class RuneArt < ApplicationRecord
  # Riftbound's six domains, each with its rune color.
  DOMAINS = {
    "Fury"  => { color: "#e0453a", label: "Red" },
    "Calm"  => { color: "#3fae6a", label: "Green" },
    "Mind"  => { color: "#3b82f6", label: "Blue" },
    "Body"  => { color: "#f08a24", label: "Orange" },
    "Chaos" => { color: "#9b5de5", label: "Purple" },
    "Order" => { color: "#e8c547", label: "Yellow" }
  }.freeze

  VARIANTS = [ "Standard", "Alternate Art", "Promo", "Overnumbered", "Signature", "Showcase" ].freeze

  SORTS = {
    "set"     => "Set",
    "domain"  => "Color",
    "newest"  => "Newest release",
    "price"   => "Price: high to low",
    "added"   => "Recently added"
  }.freeze

  has_one_attached :image
  attr_accessor :remove_image

  validates :domain, inclusion: { in: DOMAINS.keys }
  validates :set_name, :variant, presence: true
  validates :owned_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Goal: a full playset of every art.
  COLLECTION_GOAL = 6

  def needed = [ COLLECTION_GOAL - owned_count, 0 ].max
  def complete? = owned_count >= COLLECTION_GOAL
  def cost_to_complete = market_price && market_price * needed

  def self.collection_stats
    arts = all.to_a
    {
      owned: arts.sum { [ _1.owned_count, COLLECTION_GOAL ].min },
      goal: arts.size * COLLECTION_GOAL,
      complete: arts.count(&:complete?),
      discovered: arts.count { _1.owned_count.positive? },
      total: arts.size,
      cost: arts.sum { _1.cost_to_complete || 0 },
      unpriced: arts.count { _1.needed.positive? && _1.market_price.nil? }
    }
  end

  scope :in_domain, ->(d) { d.present? ? where(domain: d) : all }
  scope :in_set,    ->(s) { s.present? ? where(set_name: s) : all }
  scope :of_variant, ->(v) { v.present? ? where(variant: v) : all }

  def self.sorted(key)
    domain_order = Arel.sql("array_position(ARRAY[#{DOMAINS.keys.map { |d| connection.quote(d) }.join(',')}]::varchar[], domain)")
    case key
    when "domain" then order(domain_order, :set_name, :collector_number)
    when "newest" then order(Arel.sql("released_on DESC NULLS LAST"), domain_order)
    when "added"  then order(created_at: :desc)
    when "price"  then order(Arel.sql("market_price DESC NULLS LAST"), domain_order)
    else order(Arel.sql("MIN(released_on) OVER (PARTITION BY set_name) NULLS LAST"), :set_name, domain_order, :collector_number)
    end
  end

  # Set names in release order.
  def self.set_names
    unscope(:order).group(:set_name).order(Arel.sql("MIN(released_on) NULLS LAST"), :set_name).pluck(:set_name)
  end

  # Friendlier row label for the compare view.
  def self.variant_label(variant)
    variant == "Promo" ? "Nexus Night" : variant
  end

  def color = DOMAINS.dig(domain, :color)

  def display_image
    image.attached? ? image : image_url.presence
  end

  def name
    title.presence || "#{domain} Rune"
  end
end
