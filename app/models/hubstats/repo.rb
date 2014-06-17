module Hubstats
  class Repo < ActiveRecord::Base

    scope :with_recent_activity, where(["updated_at > '%s'", 2.weeks.ago])
    scope :users_belonging_to_repo, lambda {|repo_id| select("user_id").where(repo_id: repo_id).group_by("user_id")}

    attr_accessible :id, :name, :full_name, :homepage, :language, :description, :default_branch,
      :url, :html_url, :clone_url, :git_url, :ssh_url, :svn_url, :mirror_url,
      :hooks_url, :issue_events_url, :events_url, :contributors_url, :git_commits_url, 
      :issue_comment_url, :merges_url, :issues_url, :pulls_url, :labels_url,
      :forks_count, :stargazers_count, :watchers_count, :size, :open_issues_count,
      :has_issues, :has_wiki, :has_downloads,:fork, :private, 
      :pushed_at, :created_at, :updated_at, :owner_id

    has_many :pull_requests
    belongs_to :owner, :class_name => "User", :foreign_key => "id"

    def self.find_or_create_repo(github_repo)
      github_repo = github_repo.to_h if github_repo.respond_to? :to_h
      repo_data = github_repo.slice(*column_names.map(&:to_sym))

      if github_repo[:owner]
        user = Hubstats::User.find_or_create_user(github_repo[:owner])
        repo_data[:owner_id] = user[:id]
      end

      repo = where(:id => repo_data[:id]).first_or_create(repo_data)
      return repo if repo.save
      Rails.logger.debug repo.errors.inspect
    end
    
    def to_param
      self.name
    end

  end
end
