class ChaptersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :authorize_edit!
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
      redirect_to edit_universe_path(@universe), notice: 'Chapter was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to edit_universe_path(@universe), notice: 'Chapter was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @chapter.destroy
    redirect_to edit_universe_path(@universe), notice: 'Chapter was successfully deleted.'
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

  def set_chapter
    @chapter = @universe.chapters.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(:name, :description)
  end
end
