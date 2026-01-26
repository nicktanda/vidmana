class ManaPromptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mana_prompt, only: [:show, :edit, :update, :destroy]

  def index
    @mana_prompts = current_user.mana_prompts.order(:created_at)
  end

  def show
  end

  def new
    @mana_prompt = current_user.mana_prompts.build(content: ManaPrompt::DEFAULT_PROMPT)
  end

  def create
    @mana_prompt = current_user.mana_prompts.build(mana_prompt_params)

    if @mana_prompt.save
      redirect_to mana_prompts_path, notice: 'Prompt was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @mana_prompt.update(mana_prompt_params)
      redirect_to mana_prompts_path, notice: 'Prompt was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.mana_prompts.count > 1
      @mana_prompt.destroy
      redirect_to mana_prompts_path, notice: 'Prompt was successfully deleted.'
    else
      redirect_to mana_prompts_path, alert: 'Cannot delete your only prompt.'
    end
  end

  private

  def set_mana_prompt
    @mana_prompt = current_user.mana_prompts.find(params[:id])
  end

  def mana_prompt_params
    params.require(:mana_prompt).permit(:name, :content, :model)
  end
end
