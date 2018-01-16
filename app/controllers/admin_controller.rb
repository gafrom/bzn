class AdminController < ApplicationController
  before_action :authenticate_user!, :set_user

  private

  def set_user
    @user = current_user
  end
end
