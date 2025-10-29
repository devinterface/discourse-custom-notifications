# frozen_string_literal: true

# name: Moderatori Plugin
# about: Nothing about
# meta_topic_id: TODO
# version: 0.0.1
# authors: DevInterface Srl
# url: Nothing url
# required_version: 2.7.0


enabled_site_setting :moderatori_enabled

add_admin_route 'custom.moderatori_plugin', 'moderatori'

Discourse::Application.routes.append do
  get '/admin/plugins/moderatori' => 'admin/plugins#index', constraints: StaffConstraint.new
  get '/moderatori/:topic_id' => 'moderatori#index'
  get '/category_read_restricted/:category_id' => 'moderatori#edit_category_read_restricted'
  post '/download_csv_topics' => 'moderatori#download_csv_topics'
  post '/custom_create_user' => 'moderatori#custom_create_user'
  post '/custom_update_email' => 'moderatori#custom_update_email'

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
    if Topic.find(object.topic.id).category_id.nil?
      return [
        false,
        false,
        ""
      ]
    else
      return [
        Topic.find(object.topic.id).try(:category).try(:groups).where("name ILIKE 'D-A_%' OR name ILIKE 'D-M_%'").count.positive?,
        notifications_count > 0,
        notifications_count > 1 ? "Mostra #{notifications_count} notifiche" : "Mostra #{notifications_count} notifica"
      ]
    end
  end

  add_to_serializer(:topic_view, :custom_notifications) do
    topic_id = object.topic.id
    Notification.where(
      topic_id: topic_id,
      notification_type: Notification.types[:invited_to_topic],
    ).order(created_at: :desc).map{|n| [n.try(:user).try(:username), n.try(:created_at).in_time_zone('Rome').strftime("%d/%m/%Y %k:%M"), n.user_id == -1 ? "Automatica" : "Manuale"]}
  end

  add_to_serializer(:topic_list_item, :all_posts_excerpt) do
    cooked_posts = object.posts.order(:post_number).pluck(:cooked).join(" ")
    PrettyText.excerpt(cooked_posts, 10000)
  end

  Notification.class_eval do
    after_create :fix_invalid_json_data

    def fix_invalid_json_data
      return unless self.data.include?("topic_title")
      fixed = self.data.dup
      fixed = fixed.gsub(/(?<=:")([^"]*?)"([^"]*?")/, '\1\" \2')
      if fixed =~ /"topic_title":"(.*)"/
        fixed = { topic_title: $1 }.to_json
      end
      self.data = fixed
      self.save!
    end
  end

  UserNotifications.class_eval do
    def send_notification_email(opts)
      post = opts[:post]
      title = opts[:title]

      allow_reply_by_email = opts[:allow_reply_by_email]
      use_site_subject = opts[:use_site_subject]
      add_re_to_subject = opts[:add_re_to_subject] && post.post_number > 1
      use_topic_title_subject = opts[:use_topic_title_subject]
      username = opts[:username]
      from_alias = opts[:from_alias]
      notification_type = opts[:notification_type]
      user = opts[:user]
      group_name = opts[:group_name]
      locale = user_locale(user)

      template = +"user_notifications.user_#{notification_type}"
      if post.topic.private_message?
        template << "_pm"

        if group_name
          template << "_group"
        elsif user.staged
          template << "_staged"
        end
      end

      # category name
      category = Topic.find_by(id: post.topic_id)&.category
      if opts[:show_category_in_subject] && post.topic_id && category && !category.uncategorized?
        show_category_in_subject = category.name

        # subcategory case
        if !category.parent_category_id.nil?
          show_category_in_subject =
            "#{Category.where(id: category.parent_category_id).pick(:name)}/#{show_category_in_subject}"
        end
      else
        show_category_in_subject = nil
      end

      # tag names
      if opts[:show_tags_in_subject] && post.topic_id
        max_tags =
          if SiteSetting.enable_max_tags_per_email_subject
            SiteSetting.max_tags_per_email_subject
          else
            SiteSetting.max_tags_per_topic
          end

        tags =
          DiscourseTagging
            .visible_tags(Guardian.new(user))
            .joins(:topic_tags)
            .where("topic_tags.topic_id = ?", post.topic_id)
            .order("tags.public_topic_count DESC", "tags.name ASC")
            .limit(max_tags)
            .pluck(:name)

        show_tags_in_subject = tags.any? ? tags.join(" ") : nil
      end

      group = post.topic.allowed_groups&.first

      if post.topic.private_message?
        subject_pm =
          if opts[:show_group_in_subject] && group.present?
            if group.full_name
              "[#{group.full_name}] "
            else
              "[#{group.name}] "
            end
          else
            I18n.t("subject_pm")
          end

        participants = self.class.participants(post, user)
      end

      if SiteSetting.private_email?
        title = I18n.t("system_messages.private_topic_title", id: post.topic_id)
      end

      context = +""
      tu = TopicUser.get(post.topic_id, user)
      context_posts = self.class.get_context_posts(post, tu, user)

      # make .present? cheaper
      context_posts = context_posts.to_a

      if context_posts.present?
        context << +"-- \n*#{I18n.t("user_notifications.previous_discussion")}*\n"
        context_posts.each { |cp| context << email_post_markdown(cp, true) }
      end

      translation_override_exists =
        TranslationOverride.where(
          locale: SiteSetting.default_locale,
          translation_key: "#{template}.text_body_template",
        ).exists?

      if opts[:use_invite_template]
        invite_template = +"user_notifications.invited"
        invite_template << "_group" if group_name

        invite_template << if post.topic.private_message?
          "_to_private_message_body"
        else
          "_to_topic_body"
        end

        ################################
        # OVERRIDE
        ################################

        topic_excerpt = ""
        post.topic.posts.order(:post_number).each do |p|
          topic_excerpt += "#{p.user.username} - #{p.created_at.strftime("%d/%m/%Y %H:%M:%S")}\n\n"
          topic_excerpt += p.cooked.tr("\n", " ")
        end

        ################################
        # FINE OVERRIDE
        ################################

        topic_url = post.topic&.url

        if SiteSetting.private_email?
          topic_excerpt = ""
          topic_url = ""
        end

        message =
          I18n.t(
            invite_template,
            username: username,
            group_name: group_name,
            topic_title: gsub_emoji_to_unicode(title),
            topic_excerpt: topic_excerpt,
            site_title: SiteSetting.title,
            site_description: SiteSetting.site_description,
            topic_url: topic_url,
          )

        html = PrettyText.cook(message, sanitize: false).html_safe
      else
        reached_limit = SiteSetting.max_emails_per_day_per_user > 0
        reached_limit &&=
          (EmailLog.where(user_id: user.id).where("created_at > ?", 1.day.ago).count) >=
            (SiteSetting.max_emails_per_day_per_user - 1)

        in_reply_to_post = post.reply_to_post if user.user_option.email_in_reply_to
        if SiteSetting.private_email?
          message = I18n.t("system_messages.contents_hidden")
        else
          message =
            email_post_markdown(post) +
              (
                if reached_limit
                  "\n\n#{I18n.t "user_notifications.reached_limit", count: SiteSetting.max_emails_per_day_per_user}"
                else
                  ""
                end
              )
        end

        first_footer_classes = "highlight"
        if (allow_reply_by_email && user.staged) || (user.suspended? || user.staged?)
          first_footer_classes = ""
        end

        unless translation_override_exists
          html =
            UserNotificationRenderer.render(
              template: "email/notification",
              format: :html,
              locals: {
                context_posts: context_posts,
                reached_limit: reached_limit,
                post: post,
                in_reply_to_post: in_reply_to_post,
                classes: Rtl.new(user).css_class,
                first_footer_classes: first_footer_classes,
                reply_above_line: false,
              },
            )
        end
      end

      email_opts = {
        topic_title: Emoji.gsub_emoji_to_unicode(title),
        topic_title_url_encoded: title ? UrlHelper.encode_component(title) : title,
        message: message,
        url: post.url(without_slug: SiteSetting.private_email?),
        post_id: post.id,
        topic_id: post.topic_id,
        context: context,
        username: username,
        group_name: group_name,
        add_unsubscribe_link: !user.staged,
        mailing_list_mode: user.user_option.mailing_list_mode,
        unsubscribe_url: post.unsubscribe_url(user),
        allow_reply_by_email: allow_reply_by_email,
        only_reply_by_email: allow_reply_by_email && user.staged,
        use_site_subject: use_site_subject,
        add_re_to_subject: add_re_to_subject,
        show_category_in_subject: show_category_in_subject,
        show_tags_in_subject: show_tags_in_subject,
        private_reply: post.topic.private_message?,
        subject_pm: subject_pm,
        participants: participants,
        include_respond_instructions: !(user.suspended? || user.staged?),
        notification_type: notification_type,
        template: template,
        use_topic_title_subject: use_topic_title_subject,
        site_description: SiteSetting.site_description,
        site_title: SiteSetting.title,
        site_title_url_encoded: UrlHelper.encode_component(SiteSetting.title),
        locale: locale,
      }

      email_opts[:html_override] = html unless translation_override_exists

      # If we have a display name, change the from address
      email_opts[:from_alias] = from_alias if from_alias.present?

      TopicUser.change(user.id, post.topic_id, last_emailed_post_number: post.post_number)

      build_email(user.email, email_opts)
    end
  end

end

# user = User.find(2099)
# notification = Notification.last
# topic = notification.topic
# message = UserNotifications.public_send(
#   "user_invited_to_topic",
#   user,
#   notification_type: Notification.types[notification.notification_type],
#   notification_data_hash: notification.data_hash,
#   post: topic.try(:posts).try(:first)
# )
# Email::Sender.new(message, :invited_to_topic).send

# DB.query("update site_settings set value = 10000 where id = 61 or id = 86;")

# select id, name, value from site_settings where name ILIKE '%length%';

# update site_settings set value = 50000 where id = 61 or id = 86;

# def fix_invalid_json_data(data)
#   return unless data.include?("topic_title")
#   fixed = data.dup.gsub(/(?<=:")([^"]*?)"([^"]*?")/, '\1\" \2')
#   if fixed =~ /"topic_title":"(.*)"/
#     fixed = { topic_title: $1 }.to_json
#   end
#   return fixed
# end