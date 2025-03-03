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

  def custom_create_user
    if !params[:new_email].present?
      render json: {error: true, text: "Inserire email"}
    elsif !params[:new_username].present?
      render json: {error: true, text: "Inserire username"}
    elsif UserEmail.where(email: params[:new_email]).exists?
      render json: {error: true, text: "Email già presente"}
    elsif User.where(username: params[:new_username]).exists? || User.where(username_lower: params[:new_username].downcase).exists?
      render json: {error: true, text: "Username già presente"}
    elsif !params[:new_password].present?
      render json: {error: true, text: "Inserire password"}
    elsif params[:new_password].length < 12
      render json: {error: true, text: "Lunghezza minima password: 12"}
    else
      u = User.new(
        name: params[:new_username],
        username: params[:new_username],
        username_lower: params[:new_username].downcase,
        active: true,
        admin: false,
        moderator: false)
      u.email = params[:new_email]
      u.password = params[:new_password]
      if u.save
        if !u.email_tokens.active.exists?
          u.email_tokens.create!(email: u.email, scope: EmailToken.scopes[:signup])
        end
        u.activate    
        render json: {error: false, text: "Utente creato!!!\nEmail: #{params[:new_email]}\nPassword: #{params[:new_password]}"}
      else
        render json: {error: true, text: u.errors.full_messages.join("\n")}
      end
  
    end
  end

  def custom_update_email
    if !params[:new_email].present?
      render json: {error: true, text: "Inserire vecchia email"}
    elsif !params[:old_email].present?
      render json: {error: true, text: "Inserire nuova email"}
    elsif !UserEmail.where(email: params[:old_email]).exists?
      render json: {error: true, text: "Utente #{params[:old_email]} non presente"}
    elsif UserEmail.where(email: params[:new_email]).exists?
      render json: {error: true, text: "Nuova email #{params[:new_email]} già presente"}
    else
      u = UserEmail.find_by(email: params[:old_email]).user
      u.email = params[:new_email]
      if u.save
        render json: {error: false, text: "Nuova email: #{params[:new_email]}"}
      else
        render json: {error: true, text: u.errors.full_messages.join("\n")}
      end
  
    end
  end

end
