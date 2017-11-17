require "toodoo/version"
require "toodoo/init_db"
require 'highline/import'
require 'pry'
require 'date'

module Toodoo
  class User < ActiveRecord::Base
    validates :name, presence: true
    has_many :lists
    has_many :items, through: :lists
  end

  class List <ActiveRecord::Base
    validates :title, presence: true
    belongs_to :user
    has_many :items
  end

  class Item <ActiveRecord::Base
    belongs_to :list

    scope :overdue, -> (now) { where.not(due_date: nil).where('due_date < ?', now) }
    scope :done, -> (bool) { where(task_done: bool) }

    def update_due_date(due_date)
      self.update(due_date: due_date)
    end
  end
end

class TooDooApp
   include Toodoo

  def initialize
    @user = nil
    @todos = nil
    @show_done = nil
  end

  def new_user
    say("Creating a new user:")
    name = ask("Username?") { |q| q.validate = /\A\w+\Z/ }
    @user = Toodoo::User.create(:name => name)
    say("We've created your account and logged you in. Thanks #{@user.name}!")
  end

  def login
    choose do |menu|
      menu.prompt = "Please choose an account: "

      Toodoo::User.find_each do |u|
        menu.choice(u.name, "Login as #{u.name}.") { @user = u }
      end

      menu.choice(:back, "Just kidding, back to main menu!") do
        say "You got it!"
        @user = nil
      end
    end
  end

  def delete_user
    query = "Are you *sure* you want to stop using TooDoo?"

    if delete_validation(query) == 'y'
      @user.destroy
      @user = nil
    end
  end

  def new_todo_list
    say('Creating a new todo list.')
    title = ask("What do you want to name your Toodoo list as?")
    @todos = @user.lists.create(:title => title)
  end

  def pick_todo_list
    choose do |menu|
      menu.prompt = 'Which Toodoo list do you want to use?'

      @user.lists.find_each do |list|
        menu.choice(list.title) { @todos = list }
      end

      menu.choice(:back, "Just kidding, back to the main menu!") { back }
    end
  end

  def delete_todo_list
    choose do |menu|
      menu.prompt = 'Which Toodoo list do you want to delete?'

      @user.lists.find_each do |list|
        menu.choice(list.title) do
          query = "Are you *sure* you want to delete this list?"

          if delete_validation(query) == 'y'
            list.destroy
            @todos = nil
          end
        end
      end
    end
  end

  def delete_validation(query)
    choices = 'yn'

    ask(query) do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
  end

  def new_task
    task = ask("What task would you like to add?")
    item = @todos.items.create(:name => task)

    item.update_due_date(new_date)
  end

  def mark_done
    choose do |menu|
      menu.prompt = 'Which Toodoo task is done?'

      @todos.items.find_each do |item|
        menu.choice(item.name) do
          say "#{item.name} is done!"
          item.update(task_done: true)
        end
      end
    end
  end

  def change_due_date
    choose do |menu|
      menu.prompt = 'Which Toodoo task needs a new date?'

      @todos.items.find_each do |item|
        menu.choice(item.name) { item.update_due_date(new_date) }
      end
    end
  end

  def new_date
    due_date = ask('Select date as MM/DD/YYYY or hit enter to skip.')

    if due_date =~ /^(0[1-9]|1[0-2])\/(0[1-9]|1\d|2\d|3[01])\/(19|20)\d{2}$/
      Date.strptime(due_date, '%m/%d/%Y')
    end
  end

  def edit_task
    choose do |menu|
      menu.prompt = 'Which Toodoo task needs editing?'

      @todos.items.find_each do |item|
        menu.choice(item.name) do
          name = ask 'What do you want to change the task to?'
          say "#{item.name} is now #{name}!"
          item.update(name: name)
        end
      end
    end
  end

  def show_overdue
    @todos.items.overdue(Date.today).order(:due_date).each do |item|
      puts "#{item.due_date} -- #{item.name}"
    end
  end

  def show_done
    @show_done = !@show_done

    if @show_done
      say('Completed tasks:')
      bool = true
    else
      say('Incomplete tasks:')
      bool = false
    end

    @todos.items.done(bool).each { |item| puts item.name }
  end

  def back
    say "You got it!"
    @todos = nil
  end

  def run
    say "Welcome to your personal TooDoo app."
    loop do
      choose do |menu|
        menu.layout = :menu_only
        menu.shell = true

        # Are we logged in yet?
        unless @user
          menu.choice(:new_user, "Create a new user.") { new_user }
          menu.choice(:login, "Login with an existing account.") { login }
        end

        # We're logged in. Do we have a todo list to work on?
        if @user && !@todos
          menu.choice(:delete_account, "Delete the current user account.") { delete_user }
          menu.choice(:new_list, "Create a new todo list.") { new_todo_list }
          menu.choice(:pick_list, "Work on an existing list.") { pick_todo_list }
          menu.choice(:remove_list, "Delete a todo list.") { delete_todo_list }
        end

        # Let's work on some todos!
        if @todos
          menu.choice(:new_task, "Add a new task.") { new_task }
          menu.choice(:mark_done, "Mark a task finished.") { mark_done }
          menu.choice(:move_date, "Change a task's due date.") { change_due_date }
          menu.choice(:edit_task, "Update a task's description.") { edit_task }
          menu.choice(:show_done, "Toggle display of tasks you've finished.") { show_done }
          menu.choice(:show_overdue, "Show a list of task's that are overdue, oldest first.") { show_overdue }
          menu.choice(:back, "Go work on another Toodoo list!") { back }
        end

        menu.choice(:quit, "Quit!") { exit }
      end
    end
  end
end

TooDooApp.new.run
