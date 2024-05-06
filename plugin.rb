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
      user = User.find(1)
      topic = Topic.find(args[:topic_id])
      post = topic.posts.first
      notification = Notification.create({
          user_id: user.id,
          topic_id: topic.id,
          read: false,
          notification_type: Notification.types[:invited_to_topic],
          data: "{\"topic_title\":\"#{topic.title}\"}",
          high_priority: true
        })
      Group.where("name ILIKE 'D-A_%'").each do |group|
        group.users.each do |user|
          message = UserNotifications.public_send(
            "user_invited_to_topic",
            user,
            notification_type: Notification.types[notification.notification_type],
            notification_data_hash: notification.data_hash,
            post: post,
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


  class NewTopicObserver
    def self.topic_created(topic)
      @pending_topics ||= {}
      @pending_topics[topic.id] = topic
    end
  
    def self.post_created(post)
      if @pending_topics && @pending_topics.key?(post.topic_id)
        topic = post.topic
        Jobs.enqueue(:send_email_job, topic_id: topic.id)
        @pending_topics.delete(post.topic_id)
      end
    end
  end
  
  Topic.class_eval do
    after_create :notify_topic_created
  
    def notify_topic_created
      NewTopicObserver.topic_created(self)
    end
  end
  
  Post.class_eval do
    after_create :notify_post_created
  
    def notify_post_created
      if self.is_first_post?
        NewTopicObserver.post_created(self)
      end
    end
  end

  require_relative "lib/custom_function"

  class ::User
    include CustomFunction
  end

end