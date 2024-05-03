# frozen_string_literal: true

class ModeratoriController < ::ApplicationController
  requires_plugin Moderatori::PLUGIN_NAME

  def index
    topic = Topic.find(params[:topic_id])
    Group.where("name ILIKE 'D-M_%'").each do |group|
      group.users.each do |user|
        notification = Notification.create({
          user_id: user.id,
          topic_id: topic.id,
          read: false,
          notification_type: Notification.types[:invited_to_topic],
          data: "{\"topic_title\":\"#{topic.title}\"}",
          high_priority: true
        })
      end
    end
    render json: { title: notification.id }
  end
end
