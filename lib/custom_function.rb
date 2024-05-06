module CustomFunction
  def check_moderatori
    return GroupUser.where(user_id: self.id).map{|gu| gu.group.name}.include? "Moderatori"
  end
end