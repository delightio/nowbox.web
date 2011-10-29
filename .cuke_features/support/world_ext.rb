module StoresUserInfo
  attr_reader :current_user
  def set_current_user user
    if user.class != Hash
      @current_user = user.serializable_hash
    else
      @current_user = user
    end
  end
end

World(StoresUserInfo)
