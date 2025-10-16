class BeatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scene
  before_action :set_beat, only: [:show, :edit, :update, :destroy]

  def index
    @beats = @scene.beats.order(:created_at)
  end

  def show
  end

  def new
    @beat = @scene.beats.build
  end

  def create
    @beat = @scene.beats.build(beat_params)

    if @beat.save
      redirect_to universe_chapter_scene_beat_path(@scene.chapter.universe, @scene.chapter, @scene, @beat), notice: 'Beat was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @beat.update(beat_params)
      redirect_to universe_chapter_scene_beat_path(@scene.chapter.universe, @scene.chapter, @scene, @beat), notice: 'Beat was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @beat.destroy
    redirect_to universe_chapter_scene_beats_path(@scene.chapter.universe, @scene.chapter, @scene), notice: 'Beat was successfully deleted.'
  end

  private

  def set_scene
    @scene = Scene.find(params[:scene_id])
    @chapter = @scene.chapter
    @universe = @chapter.universe
  end

  def set_beat
    @beat = @scene.beats.find(params[:id])
  end

  def beat_params
    params.require(:beat).permit(:title, :description)
  end
end
