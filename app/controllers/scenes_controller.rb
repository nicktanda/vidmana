class ScenesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chapter
  before_action :set_scene, only: [:show, :edit, :update, :destroy]

  def index
    @scenes = @chapter.scenes.order(:created_at)
  end

  def show
  end

  def new
    @scene = @chapter.scenes.build
  end

  def create
    @scene = @chapter.scenes.build(scene_params)

    if @scene.save
      redirect_to universe_chapter_scene_path(@chapter.universe, @chapter, @scene), notice: 'Scene was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @scene.update(scene_params)
      redirect_to universe_chapter_scene_path(@chapter.universe, @chapter, @scene), notice: 'Scene was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @scene.destroy
    redirect_to universe_chapter_scenes_path(@chapter.universe, @chapter), notice: 'Scene was successfully deleted.'
  end

  private

  def set_chapter
    @chapter = Chapter.find(params[:chapter_id])
    @universe = @chapter.universe
  end

  def set_scene
    @scene = @chapter.scenes.find(params[:id])
  end

  def scene_params
    params.require(:scene).permit(:name, :description)
  end
end
