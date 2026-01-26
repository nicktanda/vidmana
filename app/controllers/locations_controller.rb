class LocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :authorize_edit!
  before_action :set_location, only: [:show, :edit, :update, :destroy]

  def index
    @locations = @universe.locations.order(:created_at)
  end

  def show
  end

  def new
    @location = @universe.locations.build
  end

  def create
    @location = @universe.locations.build(location_params)

    if @location.save
      redirect_to edit_universe_path(@universe), notice: 'Location was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @location.update(location_params)
      redirect_to edit_universe_path(@universe), notice: 'Location was successfully updated.'
    else
      redirect_to edit_universe_path(@universe), alert: 'Failed to update location.'
    end
  end

  def destroy
    @location.destroy
    redirect_to edit_universe_path(@universe), notice: 'Location was successfully deleted.'
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

  def set_location
    @location = @universe.locations.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :description, :location_type)
  end
end
