# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    if user.instance_of?(AdminUser)
      can :manage, Image, :all
    elsif user.user?
      can :manage, Image, user: user
    elsif user.supervisor?
      can :read, Image, :all
    end
  end
end
