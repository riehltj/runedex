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
    "added"   => "Recently added"
  }.freeze

  has_one_attached :image
  attr_accessor :remove_image

  validates :domain, inclusion: { in: DOMAINS.keys }
  validates :set_name, :variant, presence: true

  scope :in_domain, ->(d) { d.present? ? where(domain: d) : all }
  scope :in_set,    ->(s) { s.present? ? where(set_name: s) : all }
  scope :of_variant, ->(v) { v.present? ? where(variant: v) : all }

  def self.sorted(key)
    domain_order = Arel.sql("array_position(ARRAY[#{DOMAINS.keys.map { |d| connection.quote(d) }.join(',')}]::varchar[], domain)")
    case key
    when "domain" then order(domain_order, :set_name, :collector_number)
    when "newest" then order(Arel.sql("released_on DESC NULLS LAST"), domain_order)
    when "added"  then order(created_at: :desc)
    else order(Arel.sql("MIN(released_on) OVER (PARTITION BY set_name) NULLS LAST"), :set_name, domain_order, :collector_number)
    end
  end

  def self.set_names
    distinct.order(:set_name).pluck(:set_name)
  end

  def color = DOMAINS.dig(domain, :color)

  def display_image
    image.attached? ? image : image_url.presence
  end

  def name
    title.presence || "#{domain} Rune"
  end
end
