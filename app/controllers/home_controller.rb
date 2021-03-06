class HomeController < ApplicationController
  respond_to :json, :html

  skip_before_filter :verify_authenticity_token

  before_action :verify_auth_token, only: :hook

  protect_from_forgery :except => :deploy_notification

  def index
    render :text => 'ACK'
  end

  def hook
    #process_deploy_hooks
    puts "hello"
    Job.new.async.sanity_build(method(:trigger_ci_build))
    render nothing: true
  end

private

  def process_deploy_hooks
    hooks = AppSettings.hooks
    return if (hooks.blank? || !hooks.is_a?(Hash))
    hooks.each do |name, config|
      url, method, p = config.values_at('url', 'method', 'params')
      method ||= 'get'
      p ||= {}

      if url.present?
        RestClient.send(method, url, params.merge(p))
      end
    end
  end

  def verify_auth_token
    if params['token'] != AppSettings.app.token
      raise ActiveRecord::RecordNotFound
    end
  end

  def trigger_ci_build
    prepare_git_working_dir
    repo = Git.clone(temp_github_url, 'workato_temp', :path => git_working_dir_base)
    repo.config('user.name', 'Manmeet Saluja')
    repo.config('user.email', 'manmeet@workato.com')
    message = touch_readme
    repo.add(all: true)
    repo.commit(message)
    repo.push("origin")
  end

  def git_working_dir_base
    Rails.root.join('tmp')
  end

  def git_working_dir
    File.join(git_working_dir_base, 'workato_temp')
  end

  def prepare_git_working_dir
    FileUtils.rm_rf(git_working_dir)
    FileUtils.mkdir_p(git_working_dir)
  end

  def temp_github_url
    "https://#{ENV['TESTING_TOKEN']}@github.com/codemanmeet/workato.git"
  end

  def touch_readme
    "Build at #{Time.now} #codeship_feature_tests".tap do |message|
      File.open(File.join(git_working_dir, 'README.md'), 'w') do |file|
        file.puts(message)
      end
    end
  end
end
