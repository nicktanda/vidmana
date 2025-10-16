class ChaptersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :set_chapter, only: [:show, :edit, :update, :destroy]

  def index
    @chapters = @universe.chapters.order(:created_at)
  end

  def show
  end

  def new
    @chapter = @universe.chapters.build
  end

  def create
    @chapter = @universe.chapters.build(chapter_params)

    if @chapter.save
      redirect_to universe_chapter_path(@universe, @chapter), notice: 'Chapter was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to universe_chapter_path(@universe, @chapter), notice: 'Chapter was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @chapter.destroy
    redirect_to universe_chapters_path(@universe), notice: 'Chapter was successfully deleted.'
  end

  private

  def set_universe
    @universe = current_user.universes.find(params[:universe_id])
  end

  def set_chapter
    @chapter = @universe.chapters.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(:name, :description)
  end
end
