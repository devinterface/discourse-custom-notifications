# frozen_string_literal: true

class ModeratoriController < ::ApplicationController
  requires_plugin Moderatori::PLUGIN_NAME

  def index
    topic = Topic.find(params[:topic_id])
    if topic.try(:category).try(:groups).where("name ILIKE 'D-A_%' OR name ILIKE 'D-M_%'").count.positive?
      Jobs.enqueue(:send_email_job, topic_id: topic.id, group_type: "D-M_", user_id: current_user.id)
      s = ""
      topic.try(:category).try(:groups).where("name ILIKE 'D-A_%' OR name ILIKE 'D-M_%'").map{|g| s += "#{g.name}; "}
      render json: { sent: true, groups_name: s }
    else
      render json: { sent: false, groups_name: "" }
    end
  end

  def edit_category_read_restricted
    category = Category.find(params[:category_id])
    category.read_restricted = !category.read_restricted
    category.save!
  end

  def download_csv_topics
    require "csv"
    topics_id = params[:topics_id]
    order_clause = topics_id.map.with_index { |id, index| "WHEN #{id} THEN #{index}" }.join(' ')

    csv_name = "Topics_#{Time.now.strftime('%Y_%m_%d__%H_%M_%S')}.csv"
    csv_file = CSV.generate(col_sep: ';') do |csv|
      csv << ["Id","Titolo","Creazione","Sommario","Link"]
      Topic.where(id: topics_id).order(Arel.sql("CASE id #{order_clause} END")).each do |topic|
        topic_link = "#{Discourse.base_url}/t/#{topic.slug}/#{topic.id}"
        topic_sommario = topic.try(:posts).try(:first).try(:raw) # topic.try(:posts).try(:first).try(:excerpt) || ""
        csv << [topic.id, topic.title, topic.created_at.strftime('%d/%m/%Y %H:%M:%S'), topic_sommario, topic_link]
      end
    end

    send_data csv_file, :filename => csv_name, :content_type => "text/csv", :disposition => 'attachment'

  end

end
