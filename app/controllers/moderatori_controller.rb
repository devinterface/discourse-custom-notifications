# frozen_string_literal: true

class ModeratoriController < ::ApplicationController
  requires_plugin Moderatori::PLUGIN_NAME

  def index
    topic = Topic.find(params[:topic_id])
    user_id = current_user.id
    # questo comando lancia il job in background per mandare le mail
    Jobs.enqueue(:send_email_job, topic_id: topic.id, group_type: "D-M_", user_id: user_id)
    s = ""
    topic.try(:category).try(:groups).map{|g| s += "#{g.name}; "}
    render json: { groups_name: s }
  end

  def edit_category_read_restricted
    category = Category.find(params[:category_id])
    category.read_restricted = !category.read_restricted
    category.save!
  end

  def download_csv_topics
    require "csv"
    topics_id = params[:topics_id]

    csv_name = "Topics_#{Time.now.strftime('%Y_%m_%d__%H_%M_%S')}.csv"
    csv_file = CSV.generate(col_sep: ';') do |csv|
      csv << ["Id","Titolo","Creazione","Sommario","Link"]
      begin
        Topic.where(id: topics_id).each do |topic|
          topic_link = "#{Discourse.base_url}/t/#{topic.slug}/#{topic.id}"
          topic_sommario = topic.try(:posts).try(:first).try(:excerpt) || ""
          csv << [topic.id, topic.title, topic.created_at.strftime('%d/%m/%Y %H:%M:%S'), topic_sommario, topic_link]
        end
      rescue => e
        csv << ["#{e}"]
      end
    end

    send_data csv_file, :filename => csv_name, :content_type => "text/csv", :disposition => 'attachment'

  end

end
