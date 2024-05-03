# frozen_string_literal: true

# name: Moderatori Plugin
# about: Nothing about
# meta_topic_id: TODO
# version: 0.0.1
# authors: DevInterface
# url: Nothing url
# required_version: 2.7.0


enabled_site_setting :moderatori_enabled

add_admin_route 'moderatori.title', 'moderatori'

Discourse::Application.routes.append do
  get '/admin/plugins/moderatori' => 'admin/plugins#index', constraints: StaffConstraint.new
  get '/moderatori/:topic_id' => 'moderatori#index'
end

after_initialize do
  module ::Moderatori
    PLUGIN_NAME ||= "moderatori"
    
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Moderatori
    end
    
  end
  # require_relative "lib/my_plugin_module/engine"
  require_relative 'app/controllers/moderatori_controller'
  DiscourseEvent.on(:topic_created) do |topic, opts, user|

  #  cerco gli user dei gruppi D-A_ e gli invio notifica di apertura topic
    Group.where("name ILIKE 'D-A_%'").each do |group|
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

  end

  
end