require_dependency "hubstats/application_controller"

module Hubstats
  class ReposController < ApplicationController

    def index
      if params[:query]
        @repos = Hubstats::Repo.where("name LIKE ?", "%#{params[:query]}%").order("name ASC")
      elsif params[:id]
        @repos = Hubstats::Repo.where(id: params[:id].split(",")).order("name ASC")
      else
        @repos = Hubstats::Repo.with_recent_activity(@timespan)
      end

      respond_to do |format|
        format.json { render :json => @repos}
      end
    end

    def show
      @repo = Hubstats::Repo.where(name: params[:repo]).first
      @pull_requests = Hubstats::PullRequest.belonging_to_repo(@repo.id).updated_since(@timespan).order("updated_at DESC").limit(20)
      @users = Hubstats::User.with_pulls_or_comments(@timespan,@repo.id).only_active.limit(20)
      @deploys = Hubstats::Deploy.belonging_to_repo(@repo.id).deployed_since(@timespan).order("deployed_at DESC").limit(20)
      pull_count = Hubstats::PullRequest.belonging_to_repo(@repo.id).updated_since(@timespan).count(:all)
      deploy_count = Hubstats::Deploy.belonging_to_repo(@repo.id).deployed_since(@timespan).count(:all)
      user_count = Hubstats::User.with_pulls_or_comments(@timespan,@repo.id).only_active.length

      if Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).average(:additions).nil?
        additions = 0
      else
        additions = Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).average(:additions).round.to_i
      end

      if Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).average(:deletions).nil?
        deletions = 0
      else
        deletions = Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).average(:deletions).round.to_i
      end

      @stats_basics = {
        user_count: user_count,
        deploy_count: deploy_count,
        pull_count: pull_count,
        comment_count: Hubstats::Comment.belonging_to_repo(@repo.id).created_since(@timespan).count(:all)
      }
      @stats_additions = {
        avg_additions: additions,
        avg_deletions: deletions,
        net_additions: Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).sum(:additions).to_i -
          Hubstats::PullRequest.merged_since(@timespan).belonging_to_repo(@repo.id).sum(:deletions).to_i
      }
    end

    def dashboard
      if params[:query] ## For select 2.
        @repos = Hubstats::Repo.where("name LIKE ?", "%#{params[:query]}%").order("name ASC")
      elsif params[:id]
        @repos = Hubstats::Repo.where(id: params[:id].split(",")).order("name ASC")
      else
        @repos = Hubstats::Repo.with_all_metrics(@timespan)
          .with_id(params[:repos])
          .custom_order(params[:order])
          .paginate(:page => params[:page], :per_page => 15)
      end
      
      @stats_basics = {
        user_count: Hubstats::User.with_pulls_or_comments(@timespan).only_active.length,
        deploy_count: Hubstats::Deploy.deployed_since(@timespan).count(:all),
        pull_count: Hubstats::PullRequest.merged_since(@timespan).count(:all),
        comment_count: Hubstats::Comment.created_since(@timespan).count(:all)
      }
      @stats_additions = {
        avg_additions: Hubstats::PullRequest.merged_since(@timespan).average(:additions).round.to_i,
        avg_deletions: Hubstats::PullRequest.merged_since(@timespan).average(:deletions).round.to_i,
        net_additions: Hubstats::PullRequest.merged_since(@timespan).sum(:additions).to_i - 
          Hubstats::PullRequest.merged_since(@timespan).sum(:deletions).to_i
      }

      respond_to do |format|
        format.html
        format.json { render :json => @repos}
      end
    end
  end
end
