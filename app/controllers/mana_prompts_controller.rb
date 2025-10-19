class ManaPromptsController < ApplicationController
  before_action :authenticate_user!

  def index
    @mana_prompt = current_user.mana_prompt
  end

  def edit
    @mana_prompt = current_user.mana_prompt
  end

  def update
    @mana_prompt = current_user.mana_prompt

    if @mana_prompt.update(mana_prompt_params)
      redirect_to mana_prompts_path, notice: 'ManaPrompt was successfully updated.'
    else
      render :edit
    end
  end

  private

  def mana_prompt_params
    params.require(:mana_prompt).permit(:content)
  end
end
