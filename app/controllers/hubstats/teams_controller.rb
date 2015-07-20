require_dependency "hubstats/application_controller"

module Hubstats
  class TeamsController < Hubstats::BaseController

    # Public - Shows all of the teams by filter params lists them with metrics between the start date and end date.
    #
    # Returns - the team data
    def index
      if params[:query] ## For select 2
        @teams = Hubstats::Team.where("name LIKE ?", "%#{params[:query]}%").order("name ASC")
      elsif params[:id]
        @teams = Hubstats::Team.where(id: params[:id].split(",")).order("name ASC")
      else
        @teams = Hubstats::Team.where(hubstats: true).with_all_metrics(@start_date, @end_date)
          .with_id(params[:teams])
          .custom_order(params[:order])
          .paginate(:page => params[:page], :per_page => 15)
      end

      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => @teams}
      end
    end

    # Public - Will show the specific team along with the basic stats about that team, including all users
    # and merged PRs a team member has done within the @start_date and @end_date.
    #
    # Returns - the data of the specific team
    def show
      @team = Hubstats::Team.where(id: params[:id]).first
      @pull_requests = Hubstats::PullRequest.belonging_to_team(@team.id).merged_in_date_range(@start_date, @end_date).order("updated_at DESC").limit(20)
      @pull_count = Hubstats::PullRequest.belonging_to_team(@team.id).merged_in_date_range(@start_date, @end_date).count(:all)
      @users = @team.users.where("login NOT IN (?)", Hubstats.config.github_config["ignore_users_list"]).order("login ASC")
      @user_count = @users.length
      @comment_count = Hubstats::Comment.belonging_to_team(@users.pluck(:id)).created_in_date_range(@start_date, @end_date).count(:all)
      @net_additions = Hubstats::PullRequest.merged_in_date_range(@start_date, @end_date).belonging_to_team(@team.id).sum(:additions).to_i -
                       Hubstats::PullRequest.merged_in_date_range(@start_date, @end_date).belonging_to_team(@team.id).sum(:deletions).to_i
      @additions = Hubstats::PullRequest.merged_in_date_range(@start_date, @end_date).belonging_to_team(@team.id).average(:additions)
      @deletions = Hubstats::PullRequest.merged_in_date_range(@start_date, @end_date).belonging_to_team(@team.id).average(:deletions)      

      stats
    end

    # Public - Shows the basic stats for the teams show page.
    #
    # Returns - the data in two hashes
    def stats
      @additions ||= 0
      @deletions ||= 0
      @stats_basics = {
        pull_count: @pull_count,
        user_count: @user_count,
        comment_count: @comment_count,
        avg_additions: @additions.round.to_i,
        avg_deletions: @deletions.round.to_i,
        net_additions: @net_additions
      }
    end
  end
end