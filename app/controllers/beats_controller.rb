class BeatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :authorize_edit!
  before_action :set_beat, only: [:show, :edit, :update, :destroy]

  def index
    @beats = @universe.beats.order(:order_index, :created_at)
  end

  def show
  end

  def new
    @beat = @universe.beats.build
  end

  def create
    @beat = @universe.beats.build(beat_params)

    if @beat.save
      redirect_to edit_universe_path(@universe), notice: 'Beat was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @beat.update(beat_params)
      redirect_to edit_universe_path(@universe), notice: 'Beat was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @beat.destroy
    redirect_to edit_universe_path(@universe), notice: 'Beat was successfully deleted.'
  end

  private

  def set_universe
    @universe = Universe.find(params[:universe_id])
  end

  def authorize_edit!
    unless @universe.can_edit?(current_user)
      redirect_to @universe, alert: "You don't have permission to edit this universe."
    end
  end

  def set_beat
    @beat = @universe.beats.find(params[:id])
  end

  def beat_params
    params.require(:beat).permit(:title, :description, :order_index)
  end
end
