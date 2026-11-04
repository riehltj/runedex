namespace :prices do
  desc "Pull current TCGplayer prices for all rune arts (via tcgcsv.com)"
  task sync: :environment do
    result = TcgPriceSync.call
    puts "Prices as of #{result.as_of}: updated #{result.updated}, unmatched #{result.unmatched.size}"
    result.unmatched.each { |a| puts "  no match: #{a.set_name} #{a.collector_number} #{a.domain} (#{a.variant})" }
  end
end
