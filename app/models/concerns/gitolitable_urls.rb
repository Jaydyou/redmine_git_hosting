module GitolitableUrls
  extend ActiveSupport::Concern

  def http_user_login
    User.current.anonymous? ? '' : "#{User.current.login}@"
  end


  def git_access_path
    "#{gitolite_repository_name}.git"
  end


  def http_access_path
    "#{RedmineGitHosting::Config.get_setting(:http_server_subdir)}#{redmine_repository_path}.git"
  end


  def go_access_path
    "go/#{redmine_repository_path}"
  end


  def ssh_url
    "ssh://#{RedmineGitHosting::Config.get_setting(:gitolite_user)}@#{RedmineGitHosting::Config.get_setting(:ssh_server_domain)}/#{git_access_path}"
  end


  def git_url
    "git://#{RedmineGitHosting::Config.get_setting(:ssh_server_domain)}/#{git_access_path}"
  end


  def http_url
    "http://#{http_user_login}#{RedmineGitHosting::Config.get_setting(:http_server_domain)}/#{http_access_path}"
  end


  def https_url
    "https://#{http_user_login}#{RedmineGitHosting::Config.get_setting(:https_server_domain)}/#{http_access_path}"
  end


  def git_annex_url
    "#{RedmineGitHosting::Config.get_setting(:gitolite_user)}@#{RedmineGitHosting::Config.get_setting(:ssh_server_domain)}:#{git_access_path}"
  end


  def go_access_url
    case extra[:git_http]
    # 1 : Only https is available, good :)
    # 2 : If both http and https are available, https is prefered
    when 1, 2
      https_url
    # 3 : Only http is available, that's okay for git clone
    when 3
      http_url
    # 0 : None is available, return empty string
    when 0
      ''
    end
  end


  def go_url
    case extra[:git_http]
    # 1 : Only https is available, good :)
    # 2 : If both http and https are available, https is prefered
    when 1, 2
      "#{RedmineGitHosting::Config.get_setting(:https_server_domain)}/#{go_access_path}"
    # 3 : Only http is available, that's okay for git clone
    when 3
      "#{RedmineGitHosting::Config.get_setting(:http_server_domain)}/#{go_access_path}"
    # 0 : None is available, return empty string
    when 0
      ''
    end
  end


  def allowed_to_commit?
    User.current.allowed_to?(:commit_access, project) ? 'true' : 'false'
  end


  def allowed_to_ssh?
    !User.current.anonymous? && User.current.allowed_to?(:create_gitolite_ssh_key, nil, global: true)
  end


  def ssh_access
    { url: ssh_url, committer: allowed_to_commit? }
  end


  ## Unsecure channels (clear password), commit is disabled
  def http_access
    { url: http_url, committer: 'false' }
  end


  def https_access
    { url: https_url, committer: allowed_to_commit? }
  end


  def git_access
    { url: git_url, committer: 'false' }
  end


  def git_annex_access
    { url: git_annex_url, committer: allowed_to_commit? }
  end


  def go_access
    { url: go_url, committer: 'false' }
  end


  def available_urls
    hash = {}

    if extra[:git_http] == 2
      hash[:https] = https_access
      hash[:http]  = http_access
    end

    hash[:ssh]   = ssh_access if allowed_to_ssh? && !extra[:git_annex]
    hash[:https] = https_access if extra[:git_http] == 1
    hash[:http]  = http_access if extra[:git_http] == 3
    hash[:git]   = git_access if project.is_public? && extra[:git_daemon]
    hash[:go]    = go_access if project.is_public? && extra[:git_http] != 0
    hash[:git_annex] = git_annex_access if extra[:git_annex]

    hash
  end

end