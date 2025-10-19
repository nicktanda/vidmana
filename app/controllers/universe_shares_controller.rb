class UniverseSharesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe
  before_action :authorize_owner!
  before_action :set_share, only: [:update, :destroy]

  def create
    user = User.find_by(id: params[:user_id])

    unless user
      redirect_to @universe, alert: "User not found."
      return
    end

    if user.id == @universe.user_id
      redirect_to @universe, alert: "Cannot share universe with yourself."
      return
    end

    @share = @universe.universe_shares.build(
      user: user,
      permission_level: params[:permission_level]
    )

    if @share.save
      redirect_to @universe, notice: "Universe shared with #{user.name}."
    else
      redirect_to @universe, alert: "Failed to share universe: #{@share.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @share.update(permission_level: params[:permission_level])
      redirect_to @universe, notice: "Permission updated successfully."
    else
      redirect_to @universe, alert: "Failed to update permission."
    end
  end

  def destroy
    user_name = @share.user.name
    @share.destroy
    redirect_to @universe, notice: "Removed access for #{user_name}."
  end

  private

  def set_universe
    @universe = Universe.find(params[:universe_id])
  end

  def set_share
    @share = @universe.universe_shares.find(params[:id])
  end

  def authorize_owner!
    unless @universe.user_id == current_user.id
      redirect_to @universe, alert: "Only the owner can manage sharing."
    end
  end
end
