class CharactersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :authorize_edit!
  before_action :set_character, only: [:show, :edit, :update, :destroy]

  def index
    @characters = @universe.characters.order(:created_at)
  end

  def show
  end

  def new
    @character = @universe.characters.build
  end

  def create
    @character = @universe.characters.build(character_params)

    if @character.save
      redirect_to edit_universe_path(@universe), notice: 'Character was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @character.update(character_params)
      redirect_to edit_universe_path(@universe), notice: 'Character was successfully updated.'
    else
      redirect_to edit_universe_path(@universe), alert: 'Failed to update character.'
    end
  end

  def destroy
    @character.destroy
    redirect_to edit_universe_path(@universe), notice: 'Character was successfully deleted.'
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

  def set_character
    @character = @universe.characters.find(params[:id])
  end

  def character_params
    params.require(:character).permit(:name, :description, :role, :icon)
  end
end
