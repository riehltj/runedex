# RuneDex

Every rune. Six of each.

A collection tracker for Riftbound rune arts: the booster alt-art runes and Nexus Night promo runes from
Origins, Spiritforged, Unleashed, Vendetta and Radiance. Compare every art for a color side by side,
track owned copies toward a playset of 6, and see what it costs to finish using TCGplayer market prices.

## Setup

Requires Ruby 3.3 and PostgreSQL.

```sh
bin/setup              # install gems, create and migrate the database
bin/rails db:seed      # load the rune arts
bin/rails prices:sync  # pull current TCGplayer prices
bin/rails server
```

## Prices

Prices come from [tcgcsv.com](https://tcgcsv.com), a free daily mirror of TCGplayer's catalog
(it refreshes around 20:00 UTC). Each art is matched to its TCGplayer product by set and collector number;
set the TCGplayer product ID on an art's edit page if it doesn't match automatically.

- Development: `bin/rails prices:sync`, or the ↻ button next to the price date.
- Production: `SyncPricesJob` runs every 6 hours via Solid Queue (`config/recurring.yml`).

## Admin

Browsing is public. Set `ADMIN_PASSWORD` to require a password for adding, editing, collecting and refreshing prices.

## Credits

Card data and most images: [riftbound.org](https://riftbound.org). Riftbound is a trademark of Riot Games;
this is an unofficial fan project.
