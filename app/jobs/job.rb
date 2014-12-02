
class Job
  include SuckerPunch::Job
  workers 4

  def perform(data)
    puts data
  end

  def sanity_build(func)
    after(180){ func.call}
  end

  def later(hour)
    time_to_wait = due_in_sec(hour)
    puts time_to_wait
    after(time_to_wait) do
      begin
        trigger_ci_build
      ensure
        later(hour)
      end
    end
  end

  def due_in_sec(hour)
    now = Time.zone.now
    due_at = Time.parse(hour)
    due_in = due_at - now
    due_in = due_at + 1.day - now if due_in < 0
    due_in
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
    "ssh://git@github.com/codemanmeet/workato.git"
  end

  def touch_readme
    "Build at #{Time.now} #codeship_feature_tests".tap do |message|
      File.open(File.join(git_working_dir, 'README.md'), 'w') do |file|
        file.puts(message)
      end
    end
  end
end
