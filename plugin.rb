# frozen_string_literal: true

# name: Moderatori Plugin
# about: Nothing about
# meta_topic_id: TODO
# version: 0.0.1
# authors: DevInterface Srl
# url: Nothing url
# required_version: 2.7.0


enabled_site_setting :moderatori_enabled

add_admin_route 'moderatori.title', 'moderatori'

Discourse::Application.routes.append do
  get '/admin/plugins/moderatori' => 'admin/plugins#index', constraints: StaffConstraint.new
  get '/moderatori/:topic_id' => 'moderatori#index'
  get '/category_read_restricted/:category_id' => 'moderatori#edit_category_read_restricted'
  post '/download_csv_topics' => 'moderatori#download_csv_topics'
end

after_initialize do
  module ::Moderatori
    PLUGIN_NAME ||= "moderatori"
    
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Moderatori
    end
    
  end

  class ::Jobs::SendEmailJob < ::Jobs::Base
    sidekiq_options retry: false

    def execute(args)
      topic = Topic.find(args[:topic_id])
      notification = Notification.create({
          user_id: args[:user_id],
          topic_id: topic.id,
          read: false,
          notification_type: Notification.types[:invited_to_topic],
          data: "{\"topic_title\":\"#{topic.title}\"}",
          high_priority: false
        })
      if args[:group_type] == "D-A_"
        # quando creo topic
        topic_groups = topic.try(:category).try(:groups).where("name ILIKE 'D-A_%'")
      elsif args[:group_type] == "D-M_"
        # quando invio notifica manuale
        topic_groups = topic.try(:category).try(:groups).where("name ILIKE 'D-A_%' OR name ILIKE 'D-M_%'")
      end
      topic_groups.each do |group|
        group.try(:users).each do |user|
          message = UserNotifications.public_send(
            "user_invited_to_topic",
            user,
            notification_type: Notification.types[notification.notification_type],
            notification_data_hash: notification.data_hash,
            post: topic.try(:posts).try(:first),
          )
          Email::Sender.new(message, :invited_to_topic).send
        end
      end
    end
  
  end

  # require_relative "lib/my_plugin_module/engine"
  require_relative 'app/controllers/moderatori_controller'
  DiscourseEvent.on(:topic_created) do |topic, opts, user|
    ### un'altra modalità per un after_create
  end
  
  Post.class_eval do
    after_create :notify_post_created
  
    def notify_post_created
      if self.is_first_post? and self.user_id != -1 and self.topic.try(:category).try(:groups).where("name ILIKE 'D-A_%'").count.positive?
        Jobs.enqueue(:send_email_job, topic_id: self.topic_id, group_type: "D-A_", user_id: -1)
      elsif self.user_id == -1 and (self.topic.title.downcase.include?("esportazione") or self.topic.title.downcase.include?("backup"))
        self.topic.archetype = Archetype.default
        self.topic.save
      end
    end
  end

  SiteSetting.topic_excerpt_maxlength = 1000

  require_relative "lib/custom_function"

  class ::User
    include CustomFunction
  end

  # require_dependency File.expand_path("../app/models/discourse-custom-notifications/custom_notification", __FILE__)

  add_to_serializer(:topic_view, :notification_buttons) do
    # posso accedere allo user come scope.user.id
    topic_id = object.topic.id
    notifications_count = Notification.where(topic_id: topic_id, notification_type: Notification.types[:invited_to_topic]).count
    return [
      Topic.find(object.topic.id).try(:category).try(:groups).where("name ILIKE 'D-A_%' OR name ILIKE 'D-M_%'").count.positive?,
      notifications_count > 0,
      notifications_count > 1 ? "Mostra #{notifications_count} notifiche" : "Mostra #{notifications_count} notifica"
    ]
  end

  add_to_serializer(:topic_view, :custom_notifications) do
    topic_id = object.topic.id
    Notification.where(
      topic_id: topic_id,
      notification_type: Notification.types[:invited_to_topic],
    ).order(created_at: :desc).map{|n| [n.try(:user).try(:username), n.try(:created_at).in_time_zone('Rome').strftime("%d/%m/%Y %k:%M"), n.user_id == -1 ? "Automatica" : "Manuale"]}
  end

end