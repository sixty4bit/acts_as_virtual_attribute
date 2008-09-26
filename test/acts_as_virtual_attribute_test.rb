require 'test/unit'
require 'rubygems'
require 'activesupport'
require 'activerecord'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'acts_as_virtual_attribute'


class ActsAsVirtualAttributeTest < Test::Unit::TestCase

  def test_project_responds_to_new_tasks_attributes
    p = Project.new
    assert p.respond_to?(:new_tasks_attributes=)
  end

  def test_adding_tasks_to_project
    p = Project.new
    params = [{ "name" => "paint fence"}]
    p.new_tasks_attributes=(params)
    p.save
    assert p.tasks.length == 1
  end

  def test_project_responds_to_existing_tasks_attributes
    p = Project.new
    assert p.respond_to?(:existing_tasks_attributes=)
  end

  def test_project_responds_to_save_tasks
    p = Project.new
    assert p.respond_to?(:save_tasks)
  end

  def test_saving_existing_attribute
    p = Project.create :name => 'house chores'
    t = p.tasks.create :name => 'paint fence'
    p.existing_tasks_attributes=({p.tasks.first.id.to_s => {"name" => 'paint fence red'}})
    p.save
    p = Project.find(p.id)
    assert 'paint fence red' == p.tasks.first.name, "should have been 'paint fence red' but got '#{p.tasks.first.name}'"
  end

  def test_saving_existing_and_new
    p = Project.create :name => 'house chores'
    p.tasks.create :name => 'paint fence'
    fence_id = p.tasks.first.id.to_s
    p.existing_tasks_attributes=({fence_id => {"name" => 'paint fence red'}})
    p.new_tasks_attributes=([{"name" => 'chop wood'}])
    p.save
    p = Project.find(p.id)
    assert 2 == p.tasks.length, "Should have 2 tasks now"
    t = Task.find fence_id
    assert "paint fence red" == t.name, "Name should be changed."
  end

  def test_project_responds_to_remove_tasks_attributes
    t = Task.new
    assert t.respond_to?(:should_destroy?)
  end

  def test_removing_existing_attribute
    p = Project.create :name => 'house chores'
    t = p.tasks.create :name => 'paint fence'
    p = Project.find p.id
    assert_equal 1, p.tasks.length
    p.existing_tasks_attributes=({p.tasks.first.id.to_s => {"should_destroy" => 1}})
    p.save
    p = Project.find p.id
    assert_equal 0, p.tasks.length
  end

  def test_projects_helper_responds_to_fields_for_task
    ph = Object.new
    ph.extend ProjectsHelper
    assert ph.respond_to?(:fields_for_task), "ProjectsHelper should have fields_for_task method"
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :projects do |t|
      t.string :name
      t.timestamps
    end

    create_table :tasks do |t|
      t.string :name
      t.integer :project_id
      t.timestamps
    end
  end
end

setup_db

def cleanup_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.execute("delete from #{table}")
  end
end

module ProjectsHelper
end

class Task < ActiveRecord::Base
  belongs_to :project
end

class Project < ActiveRecord::Base
  has_many :tasks
  acts_as_virtual_attribute :tasks
end
