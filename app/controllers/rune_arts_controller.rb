class RuneArtsController < ApplicationController
  before_action :require_admin, except: %i[index show]
  before_action :set_rune_art, only: %i[show edit update destroy]

  def index
    @filters = params.permit(:domain, :set, :variant, :sort)
    @sort = RuneArt::SORTS.key?(@filters[:sort]) ? @filters[:sort] : "set"

    scoped = RuneArt.in_domain(@filters[:domain]).in_set(@filters[:set]).of_variant(@filters[:variant])
    @rune_arts = scoped.sorted(@sort).with_attached_image
    @domain_counts = RuneArt.in_set(@filters[:set]).of_variant(@filters[:variant]).group(:domain).count
    @set_names = RuneArt.set_names
    @total = RuneArt.count
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

  def destroy
    @rune_art.destroy!
    redirect_to rune_arts_path, notice: "Art removed.", status: :see_other
  end

  private

  def set_rune_art
    @rune_art = RuneArt.find(params[:id])
  end

  def rune_art_params
    params.expect(rune_art: %i[domain set_name variant title artist source image_url image collector_number released_on notes])
  end

  # Browsing is public; adding/editing requires ADMIN_PASSWORD when it is set.
  def require_admin
    password = ENV["ADMIN_PASSWORD"]
    return if password.blank?

    authenticate_or_request_with_http_basic("Rune Art Tracker") do |_user, given|
      ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end
end
