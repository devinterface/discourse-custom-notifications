# frozen_string_literal: true

class ModeratoriController < ::ApplicationController
  requires_plugin Moderatori::PLUGIN_NAME

  def index
    topic = Topic.find(params[:topic_id])
    # questo comando lancia il job in background per mandare le mail
    Jobs.enqueue(:send_email_job, topic_id: topic.id, group_type: "D-M_")
    render json: { test: "test" }
  end

  def edit_category_read_restricted
    category = Category.find(params[:category_id])
    category.read_restricted = !category.read_restricted
    category.save!
  end
end
