class RuneArtsController < ApplicationController
  before_action :require_admin, except: %i[index show]
  before_action :set_rune_art, only: %i[show edit update destroy collect]

  def index
    @filters = params.permit(:domain, :set, :variant, :sort, :view)
    @sort = RuneArt::SORTS.key?(@filters[:sort]) ? @filters[:sort] : "set"
    @view = @filters[:view] == "gallery" ? "gallery" : "compare"

    scoped = RuneArt.in_domain(@filters[:domain]).in_set(@filters[:set]).of_variant(@filters[:variant])
    @rune_arts = scoped.sorted(@sort).with_attached_image
    build_compare_matrix(@rune_arts.to_a) if @view == "compare"
    @domain_counts = RuneArt.in_set(@filters[:set]).of_variant(@filters[:variant]).group(:domain).count
    @set_names = RuneArt.set_names
    @total = RuneArt.count
    @prices_as_of = RuneArt.maximum(:price_updated_at)
    @stats = RuneArt.collection_stats
  end

  def show; end

  def new
    @rune_art = RuneArt.new(domain: params[:domain], set_name: params[:set])
  end

  def edit; end

  def create
    @rune_art = RuneArt.new(rune_art_params)
    if @rune_art.save
      redirect_to @rune_art, notice: "Art added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @rune_art.image.purge if params.dig(:rune_art, :remove_image) == "1"
    if @rune_art.update(rune_art_params)
      redirect_to @rune_art, notice: "Art updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # +1 / -1 owned copy; updates the counter and collection summary in place.
  def collect
    delta = params[:delta].to_i.clamp(-1, 1)
    @rune_art.update!(owned_count: [ @rune_art.owned_count + delta, 0 ].max)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(helpers.dom_id(@rune_art, :collect), partial: "collect", locals: { art: @rune_art }),
          turbo_stream.replace("collection-summary", partial: "collection_summary", locals: { stats: RuneArt.collection_stats })
        ]
      end
      format.html { redirect_back fallback_location: @rune_art }
    end
  end

  def refresh_prices
    result = TcgPriceSync.call
    redirect_back fallback_location: rune_arts_path,
      notice: "Prices updated for #{result.updated} arts (TCGplayer data as of #{result.as_of.strftime('%b %-d, %-l:%M %p UTC')})."
  rescue => e
    redirect_back fallback_location: rune_arts_path, alert: "Price refresh failed: #{e.message}"
  end

  def destroy
    @rune_art.destroy!
    redirect_to rune_arts_path, notice: "Art removed.", status: :see_other
  end

  private

  # Rows: each domain, split by variant. Columns: sets in release order.
  def build_compare_matrix(arts)
    present = ->(attr) { arts.map(&attr).uniq }
    @compare_sets     = RuneArt.set_names & present.(:set_name)
    @compare_domains  = RuneArt::DOMAINS.keys & present.(:domain)
    @compare_variants = RuneArt::VARIANTS & present.(:variant)
    @compare_cells    = arts.group_by { |a| [ a.domain, a.variant, a.set_name ] }
  end

  def set_rune_art
    @rune_art = RuneArt.find(params[:id])
  end

  def rune_art_params
    params.expect(rune_art: %i[domain set_name variant title artist source image_url image collector_number
                               released_on notes tcgplayer_product_id owned_count])
  end

  # Browsing is public; adding/editing requires ADMIN_PASSWORD when it is set.
  def require_admin
    password = ENV["ADMIN_PASSWORD"]
    return if password.blank?

    authenticate_or_request_with_http_basic("RuneDex") do |_user, given|
      ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end
end
