module RoleAuthorization
  extend ActiveSupport::Concern

  class AccessDenied < StandardError; end

  included do
    rescue_from AccessDenied, with: :render_access_denied
  end

  private

  def require_login!
    raise AccessDenied unless current_user
  end

  def require_role!(*roles)
    require_login!
    allowed = roles.map(&:to_s)
    raise AccessDenied unless allowed.include?(current_user.role)
  end

  def render_access_denied
    respond_to do |format|
      format.html { render plain: "Access denied", status: :forbidden }
      format.json { render json: { error: "access_denied" }, status: :forbidden }
    end
  end
end
