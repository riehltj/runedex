module RuneArtsHelper
  def rune_image_tag(art, **opts)
    src = art.display_image
    if src
      image_tag(src, alt: art.name, loading: "lazy", **opts)
    else
      tag.div(class: "#{opts[:class]} flex items-center justify-center text-5xl font-black",
              style: "background: radial-gradient(circle, #{art.color}55, #{art.color}11)") do
        tag.span(art.domain.first, style: "color: #{art.color}")
      end
    end
  end

  def domain_badge(domain, size: "")
    color = RuneArt::DOMAINS.dig(domain, :color)
    tag.span(domain, class: "badge #{size} border-0 font-semibold text-black", style: "background: #{color}")
  end

  def tcgplayer_url(art)
    "https://www.tcgplayer.com/product/#{art.tcgplayer_product_id}" if art.tcgplayer_product_id
  end

  def price_text(amount)
    amount ? number_to_currency(amount) : "—"
  end

  # Merge new filter values into the current query string.
  def filter_path(filters, **changes)
    rune_arts_path(filters.to_h.merge(changes.stringify_keys).compact_blank)
  end

  def group_key(art, sort)
    case sort
    when "set" then art.set_name
    when "domain" then art.domain
    end
  end
end
