# Instances of Roles within the system. Uses double-sided polymorphism to attribute
# roles to principals over permissionables. Allows blanket class attributation.
#
class Sanction::Role < ActiveRecord::Base  
  #--------------------------------------------------#
  #                 Associations                     #
  #--------------------------------------------------#
  belongs_to :principal, :polymorphic => true
  belongs_to :permissionable, :polymorphic => true
  validates_presence_of :permissionable_type, :if => Proc.new {|r| !r.global?}
  validates_presence_of :name

  validate :valid_role_definition

  validate_on_create :uniqueness_of_intent

  # Ensure the role is valid by definition
  def valid_role_definition
    Sanction::Role::Definition.valid_role_instance?(self)
  end

  # See if the intent of this role is captured by another role
  def uniqueness_of_intent
    conds = []
    conds << ["#{self.class.table_name}.principal_type = ? AND (#{self.class.table_name}.principal_id = ? OR #{self.class.table_name}.principal_id IS NULL)", principal_type, (principal_id || nil)]
    conds << ["#{self.class.table_name}.name = ?", name]
  
    if global?
      conds << ["#{self.class.table_name}.global = ?", true] 
    else
      conds << ["#{self.class.table_name}.permissionable_type = ? AND (#{self.class.table_name}.permissionable_id = ? OR #{self.class.table_name}.permissionable_id IS NULL)", permissionable_type, (permissionable_id || nil)]
    end

    conditions = conds.map {|c| self.class.merge_conditions(c)}.join(" AND ")
    if Sanction::Role.exists?([conditions])
      errors.add_to_base("This role is already captured by another.") 
      false
    else
      true  
    end
  end


  #--------------------------------------------------#
  #                    Scopes                        #
  #--------------------------------------------------#
  named_scope :global, :conditions => {:global => true } 

  # Expects an array of Permissionable instances.
  named_scope :for_permissionables, lambda {|permissionable_set|
    permissionable_set = [permissionable_set] unless permissionable_set.is_a? Array

    permissionables_by_klass = {}
    permissionable_set.each do |perm|
      permissionables_by_klass[perm.class.name.to_s] ||= []
      permissionables_by_klass[perm.class.name.to_s] << perm.id
    end

    conds = []
    permissionables_by_klass.each do |(klass, ids)|
      conds << ["#{self.class.table_name}.permissionable_type = ? AND (#{self.class.table_name}.permissionable_id IN (?) OR #{self.class.table_name}.permissionable_id IS NULL)", klass, ids]
    end
    conditions = conds.map { |c| merge_conditions(c) }.join(" OR ")
 
    {:select => "DISTINCT #{self.class.table_name}.*", :conditions => conditions}
  }

  # Expects an array of Principal instances.
  named_scope :for_principals, lambda {|principal_set|
    principal_set = [principal_set] unless principal_set.is_a? Array

    pricipals_by_klass = {}
    principal_set.each do |prin|
      pricipals_by_klass[prin.class.name.to_s] ||= []
      pricipals_by_klass[prin.class.name.to_s] << prin.id
    end

    conds = []
    pricipals_by_klass.each do |(klass, ids)|
      conds << ["#{self.class.table_name}.principal_type = ? AND (#{self.class.table_name}.principal_id IN (?) OR #{self.class.table_name}.principal_id IS NULL)", klass, ids]
    end
    conditions = conds.map { |c| merge_conditions(c) }.join(" OR ")

    {:select => "DISTINCT #{self.class.table_name}.*", :conditions => conditions}
  }

  #--------------------------------------------------#
  #                 Convenience                      #
  #--------------------------------------------------#
  def principal_klass
    self.principal_type.constantize
  end
  
  def permissionable_klass
    if self.permissionable_type
      self.permissionable_type.constantize
    else
      nil
    end
  end
 
  # Provides a basic description of the role.
  def describe
    prefix = ""
    if principal_id
      prefix = "#{principal_type.to_s.titleize} (#{principal_id})"
    else
      prefix = "ALL #{principal_type.to_s.pluralize.titleize}"
    end

    suffix = ""
    unless global?
      suffix = " for"
      if permissionable_id
        suffix << " #{permissionable_type.to_s.titleize} (#{permissionable_id})"
      else
        suffix << " ALL #{permissionable_type.to_s.pluralize.titleize}"
      end
    end

    role_defs = if self.permissionable_type
      permissionable_type_klass = (self.permissionable_type.blank? ? nil : self.permissionable_type.constantize)
      Sanction::Role::Definition.for(self.principal_type.constantize) & Sanction::Role::Definition.with(self.name) & Sanction::Role::Definition.over(permissionable_type_klass)
    else
      Sanction::Role::Definition.for(self.principal_type.constantize) & Sanction::Role::Definition.with(self.name)
    end
    permissions = role_defs.map(&:permissions).flatten.uniq

    suffix << (permissions.blank? ? "" : " implying #{permissions.join(', ')}")

    "#{prefix} has #{name.to_s.titleize}#{suffix}"
  end
end
